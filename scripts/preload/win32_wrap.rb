# win32_wrap.rb
# Author: Ancurio (2014)
# https://github.com/Ancurio/mkxp/issues/73
# https://pastebin.com/zXW1hdrx

# Creative Commons CC0: To the extent possible under law, Ancurio has waived
# all copyright and related or neighboring rights to win32_wrap.rb.
# https://creativecommons.org/publicdomain/zero/1.0/

# Edits by Splendide Imaginarius (2023-2024) also CC0.

# This preload script provides a subset of Win32API in a cross-platform way, so
# you can play Win32API-based games on Linux and macOS.

# To tweak behavior, you can set the following Win32API class constants in an
# earlier preload script (these are usually only helpful for debugging):
#
# NATIVE_ON_WINDOWS=false
# TOLERATE_ERRORS=false
# LOG_NATIVE=true

module Scancodes
	SDL = { :UNKNOWN => 0x00,
		:A => 0x04, :B => 0x05, :C => 0x06, :D => 0x07,
		:E => 0x08, :F => 0x09, :G => 0x0A, :H => 0x0B,
		:I => 0x0C, :J => 0x0D, :K => 0x0E, :L => 0x0F,
		:M => 0x10, :N => 0x11, :O => 0x12, :P => 0x13,
		:Q => 0x14, :R => 0x15, :S => 0x16, :T => 0x17,
		:U => 0x18, :V => 0x19, :W => 0x1A, :X => 0x1B,
		:Y => 0x1C, :Z => 0x1D, :N1 => 0x1E, :N2 => 0x1F,
		:N3 => 0x20, :N4 => 0x21, :N5 => 0x22, :N6 => 0x23,
		:N7 => 0x24, :N8 => 0x25, :N9 => 0x26, :N0 => 0x27,
		:RETURN => 0x28, :ESCAPE => 0x29, :BACKSPACE => 0x2A, :TAB => 0x2B,
		:SPACE => 0x2C, :MINUS => 0x2D, :EQUALS => 0x2E, :LEFTBRACKET => 0x2F,
		:RIGHTBRACKET => 0x30, :BACKSLASH => 0x31, :NONUSHASH => 0x32, :SEMICOLON => 0x33,
		:APOSTROPHE => 0x34, :GRAVE => 0x35, :COMMA => 0x36, :PERIOD => 0x37,
		:SLASH => 0x38, :CAPSLOCK => 0x39, :F1 => 0x3A, :F2 => 0x3B,
		:F3 => 0x3C, :F4 => 0x3D, :F5 => 0x3E, :F6 => 0x3F,
		:F7 => 0x40, :F8 => 0x41, :F9 => 0x42, :F10 => 0x43,
		:F11 => 0x44, :F12 => 0x45, :PRINTSCREEN => 0x46, :SCROLLLOCK => 0x47,
		:PAUSE => 0x48, :INSERT => 0x49, :HOME => 0x4A, :PAGEUP => 0x4B,
		:DELETE => 0x4C, :END => 0x4D, :PAGEDOWN => 0x4E, :RIGHT => 0x4F,
		:LEFT => 0x50, :DOWN => 0x51, :UP => 0x52, :NUMLOCKCLEAR => 0x53,
		:KP_DIVIDE => 0x54, :KP_MULTIPLY => 0x55, :KP_MINUS => 0x56, :KP_PLUS => 0x57,
		:KP_ENTER => 0x58, :KP_1 => 0x59, :KP_2 => 0x5A, :KP_3 => 0x5B,
		:KP_4 => 0x5C, :KP_5 => 0x5D, :KP_6 => 0x5E, :KP_7 => 0x5F,
		:KP_8 => 0x60, :KP_9 => 0x61, :KP_0 => 0x62, :KP_PERIOD => 0x63,
		:NONUSBACKSLASH => 0x64, :APPLICATION => 0x65, :POWER => 0x66, :KP_EQUALS => 0x67,
		:F13 => 0x68, :F14 => 0x69, :F15 => 0x6A, :F16 => 0x6B,
		:F17 => 0x6C, :F18 => 0x6D, :F19 => 0x6E, :F20 => 0x6F,
		:F21 => 0x70, :F22 => 0x71, :F23 => 0x72, :F24 => 0x73,
		:EXECUTE => 0x74, :HELP => 0x75, :MENU => 0x76, :SELECT => 0x77,
		:STOP => 0x78, :AGAIN => 0x79, :UNDO => 0x7A, :CUT => 0x7B,
		:COPY => 0x7C, :PASTE => 0x7D, :FIND => 0x7E, :MUTE => 0x7F,
		:VOLUMEUP => 0x80, :VOLUMEDOWN => 0x81, :LOCKINGCAPSLOCK => 0x82, :LOCKINGNUMLOCK => 0x83,
		:LOCKINGSCROLLLOCK => 0x84, :KP_COMMA => 0x85, :KP_EQUALSAS400 => 0x86, :INTERNATIONAL1 => 0x87,
		:INTERNATIONAL2 => 0x88, :INTERNATIONAL3 => 0x89, :INTERNATIONAL4 => 0x8A, :INTERNATIONAL5 => 0x8B,
		:INTERNATIONAL6 => 0x8C, :INTERNATIONAL7 => 0x8D, :INTERNATIONAL8 => 0x8E, :INTERNATIONAL9 => 0x8F,
		:LANG1 => 0x90, :LANG2 => 0x91, :LANG3 => 0x92, :LANG4 => 0x93,
		:LANG5 => 0x94, :LANG6 => 0x95, :LANG7 => 0x96, :LANG8 => 0x97,
		:LANG9 => 0x98, :ALTERASE => 0x99, :SYSREQ => 0x9A, :CANCEL => 0x9B,
		:CLEAR => 0x9C, :PRIOR => 0x9D, :RETURN2 => 0x9E, :SEPARATOR => 0x9F,
		:OUT => 0xA0, :OPER => 0xA1, :CLEARAGAIN => 0xA2, :CRSEL => 0xA3,
		:EXSEL => 0xA4, :KP_00 => 0xB0, :KP_000 => 0xB1, :THOUSANDSSEPARATOR => 0xB2,
		:DECIMALSEPARATOR => 0xB3, :CURRENCYUNIT => 0xB4, :CURRENCYSUBUNIT => 0xB5, :KP_LEFTPAREN => 0xB6,
		:KP_RIGHTPAREN => 0xB7, :KP_LEFTBRACE => 0xB8, :KP_RIGHTBRACE => 0xB9, :KP_TAB => 0xBA,
		:KP_BACKSPACE => 0xBB, :KP_A => 0xBC, :KP_B => 0xBD, :KP_C => 0xBE,
		:KP_D => 0xBF, :KP_E => 0xC0, :KP_F => 0xC1, :KP_XOR => 0xC2,
		:KP_POWER => 0xC3, :KP_PERCENT => 0xC4, :KP_LESS => 0xC5, :KP_GREATER => 0xC6,
		:KP_AMPERSAND => 0xC7, :KP_DBLAMPERSAND => 0xC8, :KP_VERTICALBAR => 0xC9, :KP_DBLVERTICALBAR => 0xCA,
		:KP_COLON => 0xCB, :KP_HASH => 0xCC, :KP_SPACE => 0xCD, :KP_AT => 0xCE,
		:KP_EXCLAM => 0xCF, :KP_MEMSTORE => 0xD0, :KP_MEMRECALL => 0xD1, :KP_MEMCLEAR => 0xD2,
		:KP_MEMADD => 0xD3, :KP_MEMSUBTRACT => 0xD4, :KP_MEMMULTIPLY => 0xD5, :KP_MEMDIVIDE => 0xD6,
		:KP_PLUSMINUS => 0xD7, :KP_CLEAR => 0xD8, :KP_CLEARENTRY => 0xD9, :KP_BINARY => 0xDA,
		:KP_OCTAL => 0xDB, :KP_DECIMAL => 0xDC, :KP_HEXADECIMAL => 0xDD, :LCTRL => 0xE0,
		:LSHIFT => 0xE1, :LALT => 0xE2, :LGUI => 0xE3, :RCTRL => 0xE4,
		:RSHIFT => 0xE5, :RALT => 0xE6, :RGUI => 0xE7, :MODE => 0x101,
		:AUDIONEXT => 0x102, :AUDIOPREV => 0x103, :AUDIOSTOP => 0x104, :AUDIOPLAY => 0x105,
		:AUDIOMUTE => 0x106, :MEDIASELECT => 0x107, :WWW => 0x108, :MAIL => 0x109,
		:CALCULATOR => 0x10A, :COMPUTER => 0x10B, :AC_SEARCH => 0x10C, :AC_HOME => 0x10D,
		:AC_BACK => 0x10E, :AC_FORWARD => 0x10F, :AC_STOP => 0x110, :AC_REFRESH => 0x111,
		:AC_BOOKMARKS => 0x112, :BRIGHTNESSDOWN => 0x113, :BRIGHTNESSUP => 0x114, :DISPLAYSWITCH => 0x115,
		:KBDILLUMTOGGLE => 0x116, :KBDILLUMDOWN => 0x117, :KBDILLUMUP => 0x118, :EJECT => 0x119,
		:SLEEP => 0x11A, :APP1 => 0x11B, :APP2 => 0x11C
	}

	SDL.default = SDL[:UNKNOWN]

	WIN32 = {
		:LBUTTON => 0x01, :RBUTTON => 0x02, :MBUTTON => 0x04,

		:BACK => 0x08, :TAB => 0x09, :RETURN => 0x0D, :SHIFT => 0x10,
		:CONTROL => 0x11, :MENU => 0x12, :PAUSE => 0x13, :CAPITAL => 0x14,
		:ESCAPE => 0x1B, :SPACE => 0x20, :PRIOR => 0x21, :NEXT => 0x22,
		:END => 0x23, :HOME => 0x24, :LEFT => 0x25, :UP => 0x26,
		:RIGHT => 0x27, :DOWN => 0x28, :PRINT => 0x2A, :INSERT => 0x2D,
		:DELETE => 0x2E,

		:N0 => 0x30, :N1 => 0x31, :N2 => 0x32, :N3 => 0x33,
		:N4 => 0x34, :N5 => 0x35, :N6 => 0x36, :N7 => 0x37, :N8 => 0x38,
		:N9 => 0x39,

		:A => 0x41, :B => 0x42, :C => 0x43, :D => 0x44, :E => 0x45, :F => 0x46,
		:G => 0x47, :H => 0x48, :I => 0x49, :J => 0x4A, :K => 0x4B, :L => 0x4C,
		:M => 0x4D, :N => 0x4E, :O => 0x4F, :P => 0x50, :Q => 0x51, :R => 0x52,
		:S => 0x53, :T => 0x54, :U => 0x55, :V => 0x56, :W => 0x57, :X => 0x58,
		:Y => 0x59, :Z => 0x5A,

		:LWIN => 0x5B, :RWIN => 0x5C,

		:NUMPAD0 => 0x60, :NUMPAD1 => 0x61, :NUMPAD2 => 0x62, :NUMPAD3 => 0x63,
		:NUMPAD4 => 0x64, :NUMPAD5 => 0x65, :NUMPAD6 => 0x66, :NUMPAD7 => 0x67,
		:NUMPAD8 => 0x68, :NUMPAD9 => 0x69,
		:MULTIPLY => 0x6A, :ADD => 0x6B, :SEPARATOR => 0x6C, :SUBSTRACT => 0x6D,
		:DECIMAL => 0x6E, :DIVIDE => 0x6F,

		:F1 => 0x70, :F2 => 0x71, :F3 => 0x72, :F4 => 0x73,
		:F5 => 0x74, :F6 => 0x75, :F7 => 0x76, :F8 => 0x77,
		:F9 => 0x78, :F10 => 0x79, :F11 => 0x7A, :F12 => 0x7B,
		:F13 => 0x7C, :F14 => 0x7D, :F15 => 0x7E, :F16 => 0x7F,
		:F17 => 0x80, :F18 => 0x81, :F19 => 0x82, :F20 => 0x83,
		:F21 => 0x84, :F22 => 0x85, :F23 => 0x86, :F24 => 0x87,

		:NUMLOCK => 0x90, :SCROLL => 0x91,
		:LSHIFT => 0xA0, :RSHIFT => 0xA1, :LCONTROL => 0xA2, :RCONTROL => 0xA3,
		:LMENU => 0xA4, :RMENU => 0xA5,
		
		:OEM_1 => 0xBA,
		:OEM_PLUS => 0xBB, :OEM_COMMA => 0xBC, :OEM_MINUS => 0xBD, :OEM_PERIOD => 0xBE,
		:OEM_2 => 0xBF, :OEM_3 => 0xC0, :OEM_4 => 0xDB, :OEM_5 => 0xDC,
		:OEM_6 => 0xDD, :OEM_7 => 0xDE
	}

	WIN32INV = WIN32.invert

	WIN2SDL = {
		:BACK => :BACKSPACE,
		:CAPITAL => :CAPSLOCK,
		:PRIOR => :PAGEUP, :NEXT => :PAGEDOWN,
		:PRINT => :PRINTSCREEN,

		:LWIN => :LGUI, :RWIN => :RGUI,

		:NUMPAD0 => :KP_0, :NUMPAD1 => :KP_1, :NUMPAD2 => :KP_2, :NUMPAD3 => :KP_3,
		:NUMPAD4 => :KP_4, :NUMPAD5 => :KP_5, :NUMPAD6 => :KP_6, :NUMPAD7 => :KP_7,
		:NUMPAD8 => :KP_8, :NUMPAD9 => :KP_9,
		:MULTIPLY => :KP_MULTIPLY, :ADD => :KP_PLUS, :SUBSTRACT => :KP_MINUS,
		:DECIMAL => :KP_DECIMAL, :DIVIDE => :KP_DIVIDE,

		:NUMLOCK => :NUMLOCKCLEAR, :SCROLL => :SCROLLLOCK,
		:LCONTROL => :LCTRL, :RCONTROL => :RCTRL,
		:LMENU => :LALT, :RMENU => :RALT,
		
		# These are OEM and can vary by country
		# Values taken from Joiplay's src/input.cpp
		:OEM_1 => :SEMICOLON,
		:OEM_PLUS => :EQUALS, :OEM_COMMA => :COMMA, :OEM_MINUS => :MINUS, :OEM_PERIOD => :PERIOD,
		:OEM_2 => :SLASH, :OEM_3 => :GRAVE, :OEM_4 => :LEFTBRACKET, :OEM_5 => :BACKSLASH,
		:OEM_6 => :RIGHTBRACKET, :OEM_7 => :APOSTROPHE
	}

	WIN2SDL.default = :UNKNOWN
end

$win32KeyStates = nil

module Graphics
	class << self
		alias_method(:win32wrap_update, :update)
		def update
			win32wrap_update
			$win32KeyStates = nil
			$maou_graphics_update_count ||= 0
			$maou_graphics_update_count += 1
			trace_graphics = (ENV["MAOU_MKXPZ_TRACE_GRAPHICS"] == "1" rescue false)
			if trace_graphics && ($maou_graphics_update_count % 120) == 0
				begin
					scene = defined?(SceneManager) && SceneManager.respond_to?(:scene) && SceneManager.scene ? SceneManager.scene.class : nil
					System.puts("[MaouTrace] Graphics.update count=#{$maou_graphics_update_count} frame=#{Graphics.frame_count} scene=#{scene} brightness=#{Graphics.brightness}")
					if scene == Scene_Title && !$maou_title_trace_done
						$maou_title_trace_done = true
						current_scene = SceneManager.scene
						sprite = current_scene.instance_variable_get(:@sprite1)
						command_window = current_scene.instance_variable_get(:@command_window)
						System.puts("[MaouTrace] Title data title1=#{$data_system.title1_name.inspect} title2=#{$data_system.title2_name.inspect} draw_title=#{$data_system.opt_draw_title.inspect}")
						if sprite && sprite.bitmap
							System.puts("[MaouTrace] Title sprite bitmap=#{sprite.bitmap.width}x#{sprite.bitmap.height} pos=#{sprite.x},#{sprite.y} visible=#{sprite.visible}")
						end
						if command_window
							System.puts("[MaouTrace] Title command window x=#{command_window.x} y=#{command_window.y} w=#{command_window.width} h=#{command_window.height} visible=#{command_window.visible} openness=#{command_window.openness}")
						end
						begin
							Graphics.snap_to_bitmap.to_file("maou-title-snapshot.png")
							System.puts("[MaouTrace] Saved maou-title-snapshot.png")
						rescue Exception => snapshot_error
							System.puts("[MaouTrace] Snapshot failed #{snapshot_error.class}: #{snapshot_error.message}")
						end
					end
				rescue Exception => e
					System.puts("[MaouTrace] Graphics.update trace failed #{e.class}: #{e.message}")
				end
			end
		end
	end
end

def get_raw_keystates
	if $win32KeyStates == nil
		$win32KeyStates = Input.raw_key_states
	end

	return $win32KeyStates
end

def common_keystate(vkey)
	vkey_name = Scancodes::WIN32INV[vkey]

	states = get_raw_keystates
	pressed = false

	if vkey_name == :LBUTTON
		pressed = Input.press?(Input::MOUSELEFT)
	elsif vkey_name == :RBUTTON
		pressed = Input.press?(Input::MOUSERIGHT)
	elsif vkey_name == :MBUTTON
		pressed = Input.press?(Input::MOUSEMIDDLE)
	elsif vkey_name == :SHIFT
		pressed = double_state(states, :LSHIFT, :RSHIFT)
	elsif vkey_name == :MENU
		pressed = double_state(states, :LALT, :RALT)
	elsif vkey_name == :CONTROL
		pressed = double_state(states, :LCTRL, :RCTRL)
	else
		scan = nil
		if Scancodes::SDL.key?(vkey_name)
			scan = vkey_name
		else
			scan = Scancodes::WIN2SDL[vkey_name]
		end

		pressed = state_pressed(states, scan)
	end

	return pressed ? 1 : 0
end

	def memcpy_string(dst, src)
		i = 0
		src.each_byte do |b|
			dst.setbyte(i, b)
			i += 1
		end
	end

	def copy_c_string(dst, src, max_size)
		max_size = max_size.to_i
		return 0 if max_size <= 0
		bytes = src.to_s.b
		copy_len = [bytes.bytesize, max_size - 1].min
		i = 0
		while i < copy_len
			dst.setbyte(i, bytes.getbyte(i))
			i += 1
		end
		dst.setbyte(copy_len, 0)
		return copy_len
	end

		def normalize_win32_path(path)
			path = path.to_s.tr("\\", "/")
			path = path[2..-1] if path.start_with?("./")
			return path
		end

		def strip_ascii_bytes(str)
			bytes = str.to_s.b
			left = 0
			right = bytes.bytesize - 1
			left += 1 while left <= right && [9, 32].include?(bytes.getbyte(left))
			right -= 1 while right >= left && [9, 32].include?(bytes.getbyte(right))
			return "" if right < left
			bytes.byteslice(left, right - left + 1)
		end

		def private_profile_value(path, section, key)
			current_section = nil
			target_section = section.to_s.downcase
			target_key = key.to_s.downcase

			File.binread(path).split(/[\r\n]+/).each do |line|
				line = strip_ascii_bytes(line)
				next if line.empty? || line.start_with?(";")
				if line.start_with?("[") && line.end_with?("]")
					current_section = strip_ascii_bytes(line[1...-1]).downcase
					next
				end
				next unless current_section == target_section
				name, raw_value = line.split("=", 2)
				next unless name && raw_value && strip_ascii_bytes(name).downcase == target_key
				return strip_ascii_bytes(raw_value)
			end

			return nil
		end

		def write_private_profile_value(path, section, key, value)
			data = File.exist?(path) ? File.binread(path) : "".b
			newline = data.include?("\r\n") ? "\r\n" : "\n"
			lines = data.split(/\r\n|\n|\r/, -1)
			lines.pop if !lines.empty? && lines.last.empty?
			target_section = section.to_s.downcase
			target_key = key.nil? ? nil : key.to_s.downcase

			section_start = nil
			section_end = lines.length
			lines.each_with_index do |line, index|
				stripped = strip_ascii_bytes(line)
				next unless stripped.start_with?("[") && stripped.end_with?("]")
				name = strip_ascii_bytes(stripped[1...-1]).downcase
				if section_start
					section_end = index
					break
				elsif name == target_section
					section_start = index
				end
			end

			if key.nil?
				lines.slice!(section_start...section_end) if section_start
			elsif section_start
				matching_key_indexes = []
				((section_start + 1)...section_end).each do |index|
					name, _ = lines[index].split("=", 2)
					matching_key_indexes << index if name && strip_ascii_bytes(name).downcase == target_key
				end
				if value.nil?
					matching_key_indexes.reverse_each { |index| lines.delete_at(index) }
				elsif matching_key_indexes.empty?
					lines.insert(section_end, "#{key}=#{value}")
				else
					lines[matching_key_indexes.shift] = "#{key}=#{value}"
					matching_key_indexes.reverse_each { |index| lines.delete_at(index) }
				end
			elsif !value.nil?
				lines << "" unless lines.empty? || lines.last.empty?
				lines << "[#{section}]"
				lines << "#{key}=#{value}"
			end

			temporary_path = "#{path}.maou-profile-#{Process.pid}-#{rand(0x1000000)}"
			begin
				File.open(temporary_path, "wb") do |file|
					file.write(lines.join(newline))
					file.write(newline) unless lines.empty?
				end
				File.rename(temporary_path, path)
			ensure
				File.delete(temporary_path) if File.exist?(temporary_path)
			end
			return true
		end

		def utf8_to_utf16le_bytes(text, include_nul)
			begin
				codepoints = text.to_s.force_encoding("UTF-8").codepoints
			rescue
			codepoints = text.to_s.b.bytes
		end
		bytes = codepoints.map { |cp| [cp > 0xffff ? 0x3f : cp].pack("v") }.join
		bytes += "\x00\x00".b if include_nul
		return bytes.b
	end

	def utf16le_bytes_to_utf8(bytes, include_nul)
		codepoints = []
		raw = bytes.to_s.b
		i = 0
		while i + 1 < raw.bytesize
			cp = raw.getbyte(i) | (raw.getbyte(i + 1) << 8)
			break if cp == 0
			codepoints << cp
			i += 2
		end
		text = codepoints.pack("U*")
		text += "\x00" if include_nul
		return text
	rescue
		return include_nul ? "\x00" : ""
	end

	def win32wrap_graphics_rect
		width = 640
		height = 480
		begin
			width = Graphics.width.to_i
			height = Graphics.height.to_i
		rescue
		end
		width = 640 if width <= 0
		height = 480 if height <= 0
		return [0, 0, width, height]
	end

def state_pressed(states, sdl_scan)
	return states[Scancodes::SDL[sdl_scan]]
end

def double_state(states, left, right)
	return state_pressed(states, left) || state_pressed(states, right)
end

		module Win32API_Impl
			module Kernel32
				class GetPrivateProfileStringA
					def call(args)
						section = args[0].to_s
						key = args[1].to_s
						default_value = args[2].to_s.b
						out = args[3]
						max_size = args[4].to_i
						path = normalize_win32_path(args[5])
						value = default_value

						begin
							value = private_profile_value(path, section, key) || default_value
						rescue Exception => e
							System.puts("[Win32API] GetPrivateProfileStringA failed #{path.inspect}: #{e.class}: #{e.message}")
						end

						begin
							System.puts("[Win32API] GetPrivateProfileStringA #{section.inspect}/#{key.inspect} #{path.inspect} -> #{value.inspect}")
						rescue
						end

						return copy_c_string(out, value, max_size)
					end
				end

				GetPrivateProfileString = GetPrivateProfileStringA

				class GetPrivateProfileIntA
					def call(args)
						section = args[0].to_s
						key = args[1].to_s
						default_value = args[2].to_i
						path = normalize_win32_path(args[3])
						value = private_profile_value(path, section, key)
						return default_value unless value

						text = strip_ascii_bytes(value)
						return text.to_i(16) if text =~ /\A[+-]?0[xX][0-9a-fA-F]+/
						return text.to_i if text =~ /\A[+-]?[0-9]+/
						return default_value
					rescue Exception => e
						System.puts("[Win32API] GetPrivateProfileIntA failed #{path.inspect}: #{e.class}: #{e.message}")
						return default_value
					end
				end

				GetPrivateProfileInt = GetPrivateProfileIntA

				class WritePrivateProfileStringA
					def call(args)
						section = args[0]
						key = args[1]
						value = args[2]
						path = normalize_win32_path(args[3])
						return 1 if section.nil? && key.nil? && value.nil?
						return 0 if section.nil? || path.empty?

						write_private_profile_value(path, section, key, value)
						return 1
					rescue Exception => e
						System.puts("[Win32API] WritePrivateProfileStringA failed #{path.inspect}: #{e.class}: #{e.message}")
						return 0
					end
				end

				WritePrivateProfileString = WritePrivateProfileStringA

			class MultiByteToWideChar
				def call(args)
					src = args[2].to_s.b
					src_len = args[3].to_i
					dst = args[4]
					dst_len = args[5].to_i

					text = src_len < 0 ? src.split("\x00", 2)[0] : src.byteslice(0, src_len).to_s
					wide = utf8_to_utf16le_bytes(text, src_len < 0)
					required_chars = wide.bytesize / 2
					return required_chars if dst.nil? || dst_len == 0

					copy_bytes = [wide.bytesize, dst_len * 2].min
					memcpy_string(dst, wide.byteslice(0, copy_bytes))
					return copy_bytes / 2
				end
			end

			class WideCharToMultiByte
				def call(args)
					wide = args[2].to_s.b
					wide_len = args[3].to_i
					dst = args[4]
					dst_len = args[5].to_i

					wide = wide_len < 0 ? wide : wide.byteslice(0, wide_len * 2).to_s
					text = utf16le_bytes_to_utf8(wide, wide_len < 0)
					return text.bytesize if dst.nil? || dst_len == 0

					copy_len = [text.bytesize, dst_len].min
					memcpy_string(dst, text.byteslice(0, copy_len))
					return copy_len
				end
			end
		end

		module User32
		class Keybd_event
			Seq = [
				[0xA4, 0, 0, 0],
				[0xD, 0, 0, 0],
				[0xD, 0, 2, 0],
				[0xA4, 0, 2, 0]]
			Seq2 = [
				[0x12, 0, 0, 0],
				[0xD, 0, 0, 0],
				[0xD, 0, 2, 0],
				[0x12, 0, 2, 0]]
			def initialize
				@index = 0
			end
			def call(args)
				seq = [args[0], args[1], args[2], args[3]]

				if seq == Seq[@index] or seq == Seq2[@index]
					@index += 1
				else
					@index = 0
				end

				if @index == 4
					@index = 0
					Graphics.fullscreen = !Graphics.fullscreen
				end
			end
		end

		class GetKeyState
			def call(vkey)
				return common_keystate(vkey[0])
			end
		end
		class GetAsyncKeyState
			PRESSED_BIT = (1 << 15)
			def call(vkey)
				return common_keystate(vkey[0]) == 1 ? PRESSED_BIT : 0
			end
		end
		class GetKeyboardState
			PRESSED_BIT = 0x80
			def call(args)
				out_states = args[0]

				Scancodes::WIN32.each do |name, val|
					pressed = common_keystate(val) == 1

					out_states.setbyte(val, pressed ? PRESSED_BIT : 0)
				end
				return 1
			end
		end

		class ShowCursor
			def initialize
				@cursor_count = 0
			end
			def call(args)
				if args[0] == 1
					@cursor_count += 1
				else
					@cursor_count -= 1
				end

				Graphics.show_cursor = @cursor_count >= 0
			end
		end

		class GetCursorPos
			def call(args)
				out = [Input.mouse_x, Input.mouse_y].pack('ll')
				memcpy_string(args[0], out)
				return 1
			end
		end

		class GetClientRect
			def call(args)
				return 0 if args[0] != 42
				memcpy_string(args[1], win32wrap_graphics_rect.pack('l4'))
				return 1
			end
		end

		class SystemParametersInfoA
			SPI_GETWORKAREA = 0x30
			def call(args)
				return 0 unless args[0].to_i == SPI_GETWORKAREA && args[2]
				memcpy_string(args[2], win32wrap_graphics_rect.pack('l4'))
				return 1
			end
		end
		SystemParametersInfo = SystemParametersInfoA

		class GetDesktopWindow
			def call(args)
				return 43
			end
		end

		class GetWindowRect
			def call(args)
				return 0 if args[0].to_i == 0 || !args[1]
				memcpy_string(args[1], win32wrap_graphics_rect.pack('l4'))
				return 1
			end
		end

		class GetWindowLongA
			def call(args)
				return 0
			end
		end
		GetWindowLong = GetWindowLongA

		class GetSystemMetrics
			def call(args)
				rect = win32wrap_graphics_rect
				return rect[2] if args[0].to_i == 0
				return rect[3] if args[0].to_i == 1
				return 0
			end
		end

		class SetWindowPos
			def call(args)
				return 1
			end
		end

		class ScreenToClient
			def call(args)
				return 1
			end
		end

			class FindWindowA
				def call(args)
					if args[0] == "RGSS Player"
						return 42
					else
						return 0
					end
				end
			end
			FindWindow = FindWindowA

				class MessageBoxA
					def call(args)
						title = args[2].to_s.tr("\x00", "")
						message = args[1].to_s.tr("\x00", "")
						System.puts("[Win32API] MessageBoxA title=#{title.inspect} message=#{message.inspect}")
						return 1
					end
				end
		end

		module WFExit
			class HookExit
				def call(args)
					return 1
				end
			end
			class ClearReset
				def call(args)
					return 1
				end
			end
			class GetToExit
				def call(args)
					return 0
				end
			end
			class GetToReset
				def call(args)
					return 0
				end
			end
			class Quit
				def call(args)
					return 1
				end
			end
		end

			module WfAudio
				class Initialize
					def call(args)
						return 0
					end
				end

				class NoOp
					def call(args)
						return 1
					end
				end

			class Query
				def call(args)
					return 0
				end
			end

			class GetRTPPath
				def call(args)
					return 0
				end
			end

				[
					:Dispose, :Pause, :Resume, :Stop, :StopSecond,
				:StopBoth, :StopBGS, :StopME, :StopSE, :StopVoice,
				:SeekClear, :SeekMemorise, :SeekSet, :BalanceSet,
				:PlayBGM, :PlayBGMMemory, :PlaySecond, :PlaySecondMemory,
				:PlayBGS, :PlayBGSMemory, :PlaySE, :PlaySEMemory,
				:PlayME, :PlayMEMemory, :PlayVoice, :PlayVoiceMemory,
				:FadeBGM, :FadeBGS, :FadeME, :SetCrossFade,
				:ReservePrimaryBGM, :ReservePrimaryBGMMemory, :CuePrimaryBGM,
				:PrimaryBGMPan, :BGSPan, :MEPan, :SEPan, :PrimaryBGMReverb,
				:BGSReverb, :MEReverb, :SEReverb, :PrimaryBGMEffect,
				:SecondryBGMEffect, :BGSEffect, :MEEffect, :SEEffect,
				:VoiceEffect, :VoiceReverb, :VoicePan, :PrimaryBGMEffectDetail,
				:SecondryBGMEffectDetail, :BGSEffectDetail, :MEEffectDetail,
				:SEEffectDetail, :VoiceEffectDetail
			].each do |name|
				const_set(name, NoOp)
			end

			[
				:IsPrimaryBGMPosition, :IsSecoundryBGMPosition, :IsBGSPosition,
				:IsVoicePositionPermilNumber, :IsVoicePositionPermilFileName,
				:IsVoicePositionNumber, :IsVoicePositionFileName,
				:IsVoicePlayingNumber, :IsVoicePlayingFileName,
				:IsPrimaryBGMCheckPoint, :IsSecoundryBGMCheckPoint,
				:IsBGSCheckPoint, :IsPrimaryBGMLoopEnd,
				:IsSecondryBGMLoopEnd, :IsBGSLoopEnd, :PrimaryBGMLength,
				:SecondryBGMLength, :BGSLength, :VoiceLengthNumber,
				:VoiceLengthFileName
			].each do |name|
				const_set(name, Query)
			end

			const_set(:GetRTPPath, GetRTPPath)
		end
	end

def kappatalize(s)
	s[0] = s[0].upcase
	return s
end

class Win32API
	NATIVE_ON_WINDOWS = true unless const_defined?("NATIVE_ON_WINDOWS")
	TOLERATE_ERRORS = true unless const_defined?("TOLERATE_ERRORS")
	LOG_NATIVE = false unless const_defined?("LOG_NATIVE")
	MKXP_NATIVE_CALL_AVAILABLE = method_defined?(:call) unless const_defined?("MKXP_NATIVE_CALL_AVAILABLE")

	alias_method :mkxp_native_initialize, :initialize
	def initialize(dll, func, *args)
		@dll = dll
		@func = func
		@called = false

		dll = kappatalize(dll.chomp(".dll"))
		func = kappatalize(func)

		if !System.is_windows? or !NATIVE_ON_WINDOWS
			if Win32API_Impl.const_defined?(dll)
				dll_impl = Win32API_Impl.const_get(dll)
				if dll_impl.const_defined?(func)
					@mkxp_wrap_impl = dll_impl.const_get(func).new
					return
				end
			end
		end

		@mkxp_native_available = false
		if MKXP_NATIVE_CALL_AVAILABLE
			begin
				mkxp_native_initialize(@dll, @func, *args)
				@mkxp_native_available = true
				return
			rescue
			end
		end

	end

	if MKXP_NATIVE_CALL_AVAILABLE
		alias_method :mkxp_native_call, :call
	else
		def mkxp_native_call(*args)
			raise RuntimeError, "Native Win32API#call is unavailable"
		end
	end
	def call(*args)
		if @mkxp_wrap_impl
			return @mkxp_wrap_impl.call(args)
		end

		if @mkxp_native_available
			if LOG_NATIVE
				System.puts("[Win32API] [#{@dll}:#{@func}] #{args.to_s}")
			end
			return mkxp_native_call(*args)
		end

		if TOLERATE_ERRORS
			@@mkxp_missing_logged ||= {}
			log_key = "#{@dll}:#{@func}"
			if !@called && !@@mkxp_missing_logged[log_key]
				System.puts("[Win32API] [#{@dll}:#{@func}] #{args.to_s}")
				@@mkxp_missing_logged[log_key] = true
			end
			@called = true unless frozen?
			return 0
		else
			raise RuntimeError, "[Win32API] [#{@dll}:#{@func}] #{args.to_s}"
		end
	end
end
