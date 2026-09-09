/*
** audio.cpp
**
** This file is part of mkxp.
**
** Copyright (C) 2013 - 2021 Amaryllis Kulla <ancurio@mapleshrine.eu>
**
** mkxp is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 2 of the License, or
** (at your option) any later version.
**
** mkxp is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with mkxp.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "audio.h"

#include "audiostream.h"
#include "soundemitter.h"
#include "sharedstate.h"
#include "sharedmidistate.h"
#include "eventthread.h"
#include "sdl-util.h"
#include "exception.h"
#include "maou_mkxpz.h"

#include <string>
#include <vector>
#include <exception>

#include <SDL_thread.h>
#include <SDL_timer.h>

struct AudioPrivate
{
    uint64_t sessionGeneration = 0;
    bool sessionClosed = false;

    void guardSession() {
        if (sessionClosed) throw Exception(Exception::RGSSError, "Audio session is closed");
    }
    
    std::vector<AudioStream*> bgmTracks;
	AudioStream bgs;
	AudioStream me;

	SoundEmitter se;

	SyncPoint &syncPoint;
    
    float volumeRatio;

	/* The 'MeWatch' is responsible for detecting
	 * a playing ME, quickly fading out the BGM and
	 * keeping it paused/stopped while the ME plays,
	 * and unpausing/fading the BGM back in again
	 * afterwards */
	enum MeWatchState
	{
		MeNotPlaying,
		BgmFadingOut,
		MePlaying,
		BgmFadingIn
	};

	struct
	{
		SDL_Thread *thread;
		AtomicFlag termReq;
		MeWatchState state;
	} meWatch;

	AudioPrivate(RGSSThreadData &rtData)
	    : bgs(ALStream::Looped, "bgs"),
	      me(ALStream::NotLooped, "me"),
	      se(rtData.config),
	      syncPoint(rtData.syncPoint),
          volumeRatio(1)
	{
        for (int i = 0; i < rtData.config.BGM.trackCount; i++) {
            std::string id = std::string("bgm" + std::to_string(i));
            bgmTracks.push_back(new AudioStream(ALStream::Looped, id.c_str()));
        }
        
		meWatch.thread = 0;
		startWatch();
	}

    void startWatch() {
        if (meWatch.thread) return;
        meWatch.state = MeNotPlaying;
        meWatch.termReq.clear();
        meWatch.thread = createSDLThread<AudioPrivate, &AudioPrivate::meWatchFun>(this, "audio_mewatch");
        if (!meWatch.thread) throw Exception(Exception::MKXPError, "Cannot start audio watcher");
    }

    void stopWatch() {
        meWatch.termReq.set();
        if (meWatch.thread) SDL_WaitThread(meWatch.thread, 0);
        meWatch.thread = 0;
    }

	~AudioPrivate()
	{
		stopWatch();
        for (auto track : bgmTracks)
            delete track;
	}
    
    AudioStream *getTrackByIndex(int index) {
        if (index < 0) index = 0;
        if (index > (int)(bgmTracks.size()) - 1) {
            throw Exception(Exception::MKXPError, "requested BGM track %d out of range (max: %d)", index, bgmTracks.size() - 1);
        }
        return bgmTracks[index];
    }

	void meWatchFun()
	{
		const float fadeOutStep = 1.f / (200  / AUDIO_SLEEP);
		const float fadeInStep  = 1.f / (1000 / AUDIO_SLEEP);

		while (true)
		{
			syncPoint.passSecondarySync(&meWatch.termReq);

			if (meWatch.termReq)
				return;

			switch (meWatch.state)
			{
			case MeNotPlaying:
			{
				me.lockStream();

				if (me.stream.queryState() == ALStream::Playing)
				{
					/* ME playing detected. -> FadeOutBGM */
                    for (auto track : bgmTracks)
                        track->extPaused = true;
                    
					meWatch.state = BgmFadingOut;
				}

				me.unlockStream();

				break;
			}

			case BgmFadingOut :
			{
				me.lockStream();

				if (me.stream.queryState() != ALStream::Playing)
				{
					/* ME has ended while fading OUT BGM. -> FadeInBGM */
					me.unlockStream();
					meWatch.state = BgmFadingIn;

					break;
				}
                
                bool shouldBreak = false;
                
                for (int i = 0; i < (int)(bgmTracks.size()); i++) {
                    AudioStream *track = bgmTracks[i];
                    
                    track->lockStream();
                    
                    float vol = track->getVolume(AudioStream::External);
                    vol -= fadeOutStep;
                    
                    if (vol < 0 || track->stream.queryState() != ALStream::Playing) {
                        /* Either BGM has fully faded out, or stopped midway. -> MePlaying */
                        track->setVolume(AudioStream::External, 0);
                        track->stream.pause();
                        track->unlockStream();
                        
                        // check to see if there are any tracks still playing,
                        // and if the last one was ended this round, this branch should exit
                        std::vector<AudioStream*> playingTracks;
                        for (auto t : bgmTracks)
                            if (t->stream.queryState() == ALStream::Playing)
                                playingTracks.push_back(t);
                        
                        
                        if (playingTracks.size() <= 0 && !shouldBreak) shouldBreak = true;
                        continue;
                    }
                    
                    track->setVolume(AudioStream::External, vol);
                    track->unlockStream();
                    
                }
                if (shouldBreak) {
                    meWatch.state = MePlaying;
                    me.unlockStream();
                    break;
                }
                
				me.unlockStream();

				break;
			}

			case MePlaying :
			{
				me.lockStream();

				if (me.stream.queryState() != ALStream::Playing)
                {
                    /* ME has ended */
                    for (auto track : bgmTracks) {
                        track->lockStream();
                        track->extPaused = false;
                        
                        ALStream::State sState = track->stream.queryState();
                        
                        if (sState == ALStream::Paused) {
                            /* BGM is paused. -> FadeInBGM */
                            track->stream.play();
                            meWatch.state = BgmFadingIn;
                        }
                        else {
                            /* BGM is stopped. -> MeNotPlaying */
                            track->setVolume(AudioStream::External, 1.0f);
                            
                            if (!track->noResumeStop)
                                track->stream.play();
                            
                            meWatch.state = MeNotPlaying;
                        }
                        
                        track->unlockStream();
                    }
				}

                me.unlockStream();

				break;
			}

			case BgmFadingIn :
			{
                for (auto track : bgmTracks)
                    track->lockStream();

				if (bgmTracks[0]->stream.queryState() == ALStream::Stopped)
				{
					/* BGM stopped midway fade in. -> MeNotPlaying */
                    for (auto track : bgmTracks)
                        track->setVolume(AudioStream::External, 1.0f);
					meWatch.state = MeNotPlaying;
                    for (auto track : bgmTracks)
                        track->unlockStream();

					break;
				}

				me.lockStream();

				if (me.stream.queryState() == ALStream::Playing)
				{
					/* ME started playing midway BGM fade in. -> FadeOutBGM */
                    for (auto track : bgmTracks)
                        track->extPaused = true;
					meWatch.state = BgmFadingOut;
					me.unlockStream();
                    for (auto track : bgmTracks)
                        track->unlockStream();

					break;
				}

				float vol = bgmTracks[0]->getVolume(AudioStream::External);
				vol += fadeInStep;

				if (vol >= 1)
				{
					/* BGM fully faded in. -> MeNotPlaying */
					vol = 1.0f;
					meWatch.state = MeNotPlaying;
				}

                for (auto track : bgmTracks)
                    track->setVolume(AudioStream::External, vol);

				me.unlockStream();
                for (auto track : bgmTracks)
                    track->unlockStream();

				break;
			}
			}

			SDL_Delay(AUDIO_SLEEP);
		}
	}
};

Audio::Audio(RGSSThreadData &rtData)
	: p(new AudioPrivate(rtData))
{}


void Audio::bgmPlay(const char *filename,
                    int volume,
                    int pitch,
                    double pos,
                    int track)
{
    p->guardSession();
    if (track == -127) {
        for (int i = 0; i < (int)p->bgmTracks.size(); i++) {
            if (i == 0) {
                continue;
            }
            p->bgmTracks[i]->stop();
        }
        
        track = 0;
    }
	p->getTrackByIndex(track)->play(filename, volume, pitch, pos);
}

void Audio::bgmStop(int track)
{
    if (track == -127) {
        for (auto track : p->bgmTracks)
            track->stop();
        
        return;
    }
    
    p->getTrackByIndex(track)->stop();
}

void Audio::bgmFade(int time, int track)
{
    if (track == -127) {
        for (auto track : p->bgmTracks)
            track->fadeOut(time);
        
        return;
    }
    
    p->getTrackByIndex(track)->fadeOut(time);
}

int Audio::bgmGetVolume(int track)
{
    if (track == -127)
        return p->bgmTracks[0]->getVolume(AudioStream::BaseRatio) * 100;
    
    return p->getTrackByIndex(track)->getVolume(AudioStream::Base) * 100;
}

void Audio::bgmSetVolume(int volume, int track)
{
    float vol = volume / 100.0;
    if (track == -127) {
        for (auto track : p->bgmTracks)
            track->setVolume(AudioStream::BaseRatio, vol);
        
        return;
    }
    p->getTrackByIndex(track)->setVolume(AudioStream::Base, vol);
}


void Audio::bgsPlay(const char *filename,
                    int volume,
                    int pitch,
                    double pos)
{
    p->guardSession();
	p->bgs.play(filename, volume, pitch, pos);
}

void Audio::bgsStop()
{
	p->bgs.stop();
}

void Audio::bgsFade(int time)
{
	p->bgs.fadeOut(time);
}


void Audio::mePlay(const char *filename,
                   int volume,
                   int pitch)
{
    p->guardSession();
	p->me.play(filename, volume, pitch);
}

void Audio::meStop()
{
	p->me.stop();
}

void Audio::meFade(int time)
{
	p->me.fadeOut(time);
}


void Audio::sePlay(const char *filename,
                   int volume,
                   int pitch)
{
    p->guardSession();
	p->se.play(filename, volume, pitch);
}

void Audio::seStop()
{
	p->se.stop();
}

void Audio::setupMidi()
{
    p->guardSession();
	shState->midiState().initIfNeeded(shState->config());
}

double Audio::bgmPos(int track)
{
	return p->getTrackByIndex(track)->playingOffset();
}

double Audio::bgsPos()
{
	return p->bgs.playingOffset();
}

void Audio::reset()
{
    for (auto track : p->bgmTracks) {
    	track->stop();
    }

	p->bgs.stop();
	p->me.stop();
	p->se.stop();
}

Audio::~Audio() { delete p; }

void Audio::beginSession(uint64_t generation)
{
    if (!generation || generation != maou_mkxpz_render_generation()
        || generation <= p->sessionGeneration || (p->sessionGeneration && !p->sessionClosed))
        throw Exception(Exception::RGSSError, "Stale or overlapping audio session");
    // RGSS1/2 eagerly initializes MIDI during SharedState construction. Move
    // that unused startup pool out of the first game's clean resource boundary.
    if (!p->sessionGeneration) shState->midiState().releaseSession();
    p->startWatch();
    p->sessionGeneration = generation;
    p->sessionClosed = false;
}

MaouAudioReport Audio::sessionResources(uint64_t generation, bool release)
{
    if (!generation || generation != maou_mkxpz_render_generation() || generation != p->sessionGeneration)
        throw Exception(Exception::RGSSError, "Stale audio resource session");
    std::vector<AudioStream *> streams = p->bgmTracks;
    streams.push_back(&p->bgs); streams.push_back(&p->me);
    if (release) {
        p->sessionClosed = true;
        p->stopWatch(); // No BGM resumption while streams are being closed.
        std::exception_ptr failure;
        for (auto stream : streams) {
            try { stream->releaseSession(); }
            catch (...) { if (!failure) failure = std::current_exception(); }
        }
        p->se.releaseSession();
        try { shState->midiState().releaseSession(); }
        catch (...) { if (!failure) failure = std::current_exception(); }
        p->volumeRatio = 1.0f;
        if (failure) std::rethrow_exception(failure);
    }
    MaouAudioReport report;
    report.closed = p->sessionClosed;
    const auto &midi = shState->midiState();
    report.midiSynths = midi.synths.size();
    report.midiSettings = midi.flSettings ? 1 : 0;
    for (const auto &synth : midi.synths) report.midiInUse += synth.inUse ? 1 : 0;
    report.watchThreads = p->meWatch.thread ? 1 : 0;
    for (auto audio : streams) {
        audio->lockStream();
        report.streams += audio->stream.source ? 1 : 0;
        report.streamThreads += audio->stream.thread ? 1 : 0;
        report.fadeThreads += (audio->fade.thread ? 1 : 0) + (audio->fadeIn.thread ? 1 : 0);
        for (auto buffer : audio->stream.alBuf) report.streamPCMBytes += AL::Buffer::getSize(buffer);
        audio->unlockStream();
    }
    report.seBuffers = p->se.buffers.getSize();
    report.seCacheBytes = p->se.bufferBytes;
    for (auto buffer : p->se.atchBufs) report.seAttachments += buffer ? 1 : 0;
    return report;
}
