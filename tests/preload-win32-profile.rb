# Regression coverage for INI-backed game settings in win32_wrap.rb.

require "tmpdir"

module Graphics
	def self.update; end
	def self.width; 544; end
	def self.height; 416; end
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

work_area = "\x00".b * 16
system_parameters_info = Win32API.new("user32", "SystemParametersInfo", %w(i i p i), "i")
raise "work area query failed" unless system_parameters_info.call(0x30, 0, work_area, 0) == 1
raise "work area dimensions were wrong" unless work_area.unpack("l4") == [0, 0, 544, 416]

find_window = Win32API.new("user32", "FindWindow", %w(p p), "i")
raise "FindWindow alias failed" unless find_window.call("RGSS Player", nil) == 42

desktop = Win32API.new("user32", "GetDesktopWindow", [], "i").call
desktop_rect = "\x00".b * 16
get_window_rect = Win32API.new("user32", "GetWindowRect", %w(i p), "i")
raise "desktop rect query failed" unless get_window_rect.call(desktop, desktop_rect) == 1
raise "desktop rect dimensions were wrong" unless desktop_rect.unpack("l4") == [0, 0, 544, 416]

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
