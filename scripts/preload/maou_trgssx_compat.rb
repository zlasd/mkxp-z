# KGC's Bitmap Extension replaces Bitmap#draw_text with TRGSSX.dll calls.
# TRGSSX is a Windows-only renderer; on other platforms those calls can be
# accepted by the Win32API compatibility layer but do not modify the bitmap.
# Restore mkxp-z's native text methods after all game scripts have loaded.

platform = RUBY_PLATFORM.to_s.downcase
non_windows = !platform.include?("mswin") &&
  !platform.include?("mingw") &&
  !platform.include?("cygwin")

if non_windows && defined?(KGC::BitmapExtension) && defined?(Bitmap)
  class Bitmap
    if method_defined?(:_draw_text)
      alias draw_text _draw_text
      alias draw_text_fast _draw_text if method_defined?(:draw_text_fast)
      alias draw_text_na _draw_text if method_defined?(:draw_text_na)
    end

    if method_defined?(:_text_size)
      alias text_size _text_size
      alias text_size_fast _text_size if method_defined?(:text_size_fast)
      alias text_size_na _text_size if method_defined?(:text_size_na)
    end
  end
end
