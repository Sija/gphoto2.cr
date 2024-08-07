require "./base"

module GPhoto2
  class CameraWidget
    class Range < Base
      # Returns the range of the widget.
      def range : ::Range(Float32, Float32)
        min, max, _ = get_range
        min..max
      end

      # Returns the increment of the widget.
      def step : Float32
        _, _, inc = get_range
        inc
      end

      # Returns the list of choices of the widget.
      def choices : Array(Float32)
        min, max, inc = get_range
        min.step(to: max, by: inc).to_a
      end

      protected def get_value
        ptr = Pointer(LibC::Float).malloc
        get_value_ptr ptr
        ptr.value.to_f32
      end

      protected def set_value(value)
        case value
        when Float
          ptr = Pointer(LibC::Float).malloc 1, LibC::Float.new(value.to_f32)
          set_value_ptr ptr
        when Int, String
          set_value value.to_f32
        else
          raise ArgumentError.new \
            "Invalid value type, expected Float | Int | String, got #{value.class}"
        end
      end

      private def get_range
        min, max, inc = LibC::Float[3]
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_range(self, pointerof(min), pointerof(max), pointerof(inc))
        {min.to_f32, max.to_f32, inc.to_f32}
      end
    end
  end
end
