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

load File.expand_path("../scripts/preload/maou_trgssx_compat.rb", __dir__)

module BMSP
  module MapFog
    module Interface
      def self.name
        raise "game singleton methods must not run from the compatibility TracePoint"
      end
    end
  end
end

module KGC
  module BitmapExtension
  end
end

class Bitmap
end

unless Bitmap.new.draw_text == :native
  raise "TRGSSX text fallback was not installed"
end
