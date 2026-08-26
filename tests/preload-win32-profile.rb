# Regression coverage for INI-backed game settings in win32_wrap.rb.

require "tmpdir"

module Graphics
	def self.update; end
end

module System
	def self.is_windows?; false; end
	def self.puts(*); end
end

class Win32API
	def initialize(*); end
	def call(*); 0; end
end

load File.expand_path("../scripts/preload/win32_wrap.rb", __dir__)

Dir.mktmpdir("mkxp-win32-profile") do |directory|
	path = File.join(directory, "Game.ini")
	File.binwrite(path, "[Game]\r\nLibrary=RGSS301.dll\r\n\r\n[AudioVol]\r\nBGM=100\r\n")

	read = Win32API.new("kernel32", "GetPrivateProfileInt", %w(p p i p), "i")
	write = Win32API.new("kernel32", "WritePrivateProfileString", %w(p p p p), "i")

	raise "initial value was not read" unless read.call("audiovol", "bgm", 55, path) == 100
	raise "setting write failed" unless write.call("AudioVol", "BGM", "35", path) == 1
	raise "updated value was not read" unless read.call("AudioVol", "BGM", 55, path) == 35
	raise "unrelated INI value changed" unless File.binread(path).include?("Library=RGSS301.dll")
	raise "new setting write failed" unless write.call("AudioVol", "SE", "40", path) == 1
	raise "new setting was not read" unless read.call("AudioVol", "SE", 55, path) == 40
	raise "missing setting ignored default" unless read.call("AudioVol", "ME", 55, path) == 55
end
