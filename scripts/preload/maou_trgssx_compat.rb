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

if non_windows
  # mkxp-z exposes every decompressed game script before it evaluates them.
  # RGSS2 has no rgss_main postload hook, so append the restoration directly to
  # the script that installs the TRGSSX-backed Bitmap methods. This runs once at
  # the correct point in script order and avoids a process-lifetime TracePoint
  # when a game does not contain KGC's extension.
  maou_trgssx_patched = false
  maou_trgssx_restore_call = "\nmaou_restore_trgssx_text_methods\n"
  if defined?($RGSS_SCRIPTS) && $RGSS_SCRIPTS.respond_to?(:each)
    $RGSS_SCRIPTS.each do |entry|
      next unless entry.respond_to?(:[]) && entry.respond_to?(:[]=)

      source = entry[3]
      next unless source.is_a?(String)
      next unless source.include?("TRGSSX") && source.include?("_draw_text")
      next if source.include?(maou_trgssx_restore_call)

      entry[3] = source + maou_trgssx_restore_call
      maou_trgssx_patched = true
    end
  end

  # Direct post-script loading remains idempotent for custom runtimes.
  maou_restore_trgssx_text_methods if !maou_trgssx_patched &&
    defined?(KGC::BitmapExtension)
end
