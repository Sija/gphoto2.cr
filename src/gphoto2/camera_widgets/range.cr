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
      #
      # NOTE: When the widget reports no (or negative) increment, the range
      # is considered continuous and only its bounds are returned.
      def choices : Array(Float32)
        min, max, inc = get_range

        if inc <= 0 || min >= max
          return min == max ? [min] : [min, max]
        end

        # Computing each choice from its index (instead of accumulating
        # the increment) avoids floating-point drift. Values are widened
        # through their shortest decimal representation, so that e.g.
        # `0.3_f32` becomes `0.3` instead of `0.30000001192...`.
        min, max, inc = {min, max, inc}.map(&.to_s.to_f64)
        count = ((max - min) / inc + CHOICES_EPSILON).floor.to_i

        Array(Float32).new(count + 1) { |i| (min + i * inc).to_f32 }
      end

      private CHOICES_EPSILON = 1e-4

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
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_range(self, out min, out max, out inc)
        {min.to_f32, max.to_f32, inc.to_f32}
      end
    end
  end
end
