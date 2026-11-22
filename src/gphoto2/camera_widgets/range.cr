require "./base"

module GPhoto2
  class CameraWidget
    class Range < Base
      # Maximum number of choices returned by `#choices`.
      MAX_CHOICES = 1_000_000

      private CHOICES_EPSILON = 1e-4

      # Relative tolerance for floating-point roundoff, way below `CHOICES_EPSILON`.
      private ROUNDOFF_EPSILON = 1e-9

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
      # NOTE: When the widget reports no (or negative, or NaN) increment,
      # the range is considered continuous and only its bounds are returned.
      #
      # Raises `GPhoto2::Exception` if the range has more than `MAX_CHOICES`
      # choices (i.e. generic 32-bit ranges), use `#range` and `#step` instead.
      def choices : Array(Float32)
        min, max, inc = get_range

        # NOTE: Negated, so that NaN values (failing every comparison)
        # are covered as well, instead of failing further down
        unless inc > 0 && min < max
          return min == max ? [min] : [min, max]
        end

        # Computing each choice from its index (instead of accumulating
        # the increment) avoids floating-point drift. Values are widened
        # through their shortest decimal representation, so that e.g.
        # `0.3_f32` becomes `0.3` instead of `0.30000001192...`.
        min, max, inc = {min, max, inc}.map(&.to_s.to_f64)
        count = ((max - min) / inc + CHOICES_EPSILON).floor

        # The tolerance must not push the last choice over the maximum,
        # while a roundoff error must not drop it (see below)
        overshoot = (min + count * inc) - max
        count -= 1 if overshoot > inc * ROUNDOFF_EPSILON

        if count >= MAX_CHOICES
          raise GPhoto2::Exception.new \
            "Too many choices, use #range and #step instead"
        end

        Array(Float32).new(count.to_i + 1) do |i|
          # Clamped, so that the roundoff error doesn't exceed the maximum,
          # i.e. `-0.3 + 3 * 0.1` gives `5.55e-17` instead of `0.0`
          Math.min(min + i * inc, max).to_f32
        end
      end

      # Compares the `#value` with the given number numerically, instead
      # of using `#to_s` (which would give i.e. `"3.0"` for `3`).
      #
      # ```
      # camera[:exposurecompensation] == 0
      # ```
      def ==(other : Number) : Bool
        # `Float32` values are widened through their shortest decimal
        # representation (see `#choices`), so that i.e. `0.3_f32` equals `0.3`
        other = other.to_s.to_f64 if other.is_a?(Float32)
        get_value.to_s.to_f64 == other
      end

      # Compares the `#value` with the number given as a string (as accepted
      # by `#value=`) numerically, or with `#to_s` if it's not a number.
      #
      # ```
      # camera[:exposurecompensation] == "0.30"
      # ```
      def ==(other : String) : Bool
        (number = other.to_f64?) ? self == number : super
      end

      protected def get_value
        value = uninitialized LibC::Float
        get_value_ptr pointerof(value)
        value.to_f32
      end

      protected def set_value(value)
        case value
        when Float
          # libgphoto2 stores the value as a C `float`
          unless value.finite? && value.abs <= Float32::MAX
            raise ArgumentError.new("Invalid value: #{value}")
          end
          float = LibC::Float.new(value)
          set_value_ptr pointerof(float)
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
