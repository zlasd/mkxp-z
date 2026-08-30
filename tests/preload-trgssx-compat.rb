# Regression coverage for scripts/preload/maou_trgssx_compat.rb.

class Bitmap
  def native_draw_text
    :native
  end

  alias _draw_text native_draw_text

  def draw_text
    :trgssx
  end
end

$RGSS_SCRIPTS = [
  [0, "Unrelated", nil, "class Unrelated; end"],
  [1, "KGC Bitmap Extension", nil, <<~'RUBY']
    module KGC
      module BitmapExtension
      end
    end

    class Bitmap
      TRGSSX = true

      def draw_text
        :trgssx
      end

      alias _draw_text native_draw_text
    end
  RUBY
]

load File.expand_path("../scripts/preload/maou_trgssx_compat.rb", __dir__)
load File.expand_path("../scripts/preload/maou_trgssx_compat.rb", __dir__)

unless $RGSS_SCRIPTS[0][3] == "class Unrelated; end"
  raise "unrelated game scripts must not be modified"
end
unless $RGSS_SCRIPTS[1][3].scan("maou_restore_trgssx_text_methods").length == 1
  raise "TRGSSX compatibility injection must be idempotent"
end

eval($RGSS_SCRIPTS[1][3])

unless Bitmap.new.draw_text == :native
  raise "TRGSSX text fallback was not installed"
end
