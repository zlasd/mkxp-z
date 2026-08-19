# KGC's Bitmap Extension replaces Bitmap#draw_text with TRGSSX.dll calls.
# TRGSSX is a Windows-only renderer; on other platforms those calls can be
# accepted by the Win32API compatibility layer but do not modify the bitmap.
# Restore mkxp-z's native text methods after all game scripts have loaded.

platform = RUBY_PLATFORM.to_s.downcase
non_windows = !platform.include?("mswin") &&
  !platform.include?("mingw") &&
  !platform.include?("cygwin")

def maou_restore_trgssx_text_methods
  return unless defined?(Bitmap)

  Bitmap.class_eval do
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

if non_windows && defined?(TracePoint)
  # VX (RGSS2) has no rgss_main hook, so postloadScript is never executed.
  # Watch KGC's final Bitmap class body instead and restore the methods before
  # the game's Main script starts drawing.
  maou_kgc_seen = false
  maou_trgssx_trace = TracePoint.new(:end) do |trace|
    target_name = trace.self.respond_to?(:name) ? trace.self.name.to_s : ""
    maou_kgc_seen = true if target_name == "KGC::BitmapExtension"
    if maou_kgc_seen && target_name == "Bitmap" &&
        trace.self.method_defined?(:_draw_text)
      maou_restore_trgssx_text_methods
      maou_trgssx_trace.disable
    end
  end
  maou_trgssx_trace.enable
elsif non_windows && defined?(KGC::BitmapExtension)
  # Fallback for runtimes without TracePoint (the bundled macOS runtime has
  # TracePoint, but this keeps the script safe on older ports).
  maou_restore_trgssx_text_methods
end
