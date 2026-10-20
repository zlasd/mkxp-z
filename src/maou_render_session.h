#ifndef MAOU_RENDER_SESSION_H
#define MAOU_RENDER_SESSION_H
#include <atomic>
#include <cstdint>
#include <cmath>
#include <mutex>
// One generation and its cancellation bit share a CAS word. A late cancel can
// never overwrite a later generation's cancellation or reopen a finished one.
class MaouRenderSession {
    std::atomic<uint64_t> value{0};
    std::atomic<double> playbackSpeed{1.0};
    std::mutex speedLock;
public:
    bool begin(uint64_t id) {
        std::lock_guard<std::mutex> guard(speedLock);
        if (!id || id > UINT64_MAX / 2) return false;
        uint64_t empty = 0;
        if (!value.compare_exchange_strong(empty, id << 1)) return false;
        playbackSpeed.store(1.0);
        return true;
    }
    bool cancel(uint64_t id) {
        if (!id || id > UINT64_MAX / 2) return false;
        uint64_t expected = id << 1;
        return value.compare_exchange_strong(expected, expected | 1) || expected == ((id << 1) | 1);
    }
    bool finish(uint64_t id) {
        std::lock_guard<std::mutex> guard(speedLock);
        uint64_t expected = value.load();
        while (id && expected && (expected >> 1) == id) {
            if (value.compare_exchange_weak(expected, 0)) {
                playbackSpeed.store(1.0);
                return true;
            }
        }
        return false;
    }
    int state(uint64_t id) const {
        uint64_t current = value.load();
        return id && current && (current >> 1) == id ? (current & 1 ? 2 : 1) : 0;
    }
    bool cancelled() const { return value.load() & 1; }
    uint64_t generation() const { return value.load() >> 1; }
    bool setSpeed(uint64_t id, double speed) {
        std::lock_guard<std::mutex> guard(speedLock);
        if (state(id) != 1 || !std::isfinite(speed)) return false;
        playbackSpeed.store(speed < 0.25 ? 0.25 : speed > 8.0 ? 8.0 : speed);
        return true;
    }
    double speed() const { return playbackSpeed.load(); }
};
#endif
