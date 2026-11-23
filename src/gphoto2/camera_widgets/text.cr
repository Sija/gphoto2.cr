require "./base"

module GPhoto2
  class CameraWidget
    class Text < Base
      # Compares the `#value` with the given number numerically, unless
      # it's equal to its `#to_s` (which would give i.e. `"4.0"` for `4.0`).
      #
      # ```
      # camera[:aperture] == 4.0 # (with the value of "4")
      # ```
      def ==(other : Number) : Bool
        value = get_value
        value == other.to_s || GPhoto2.number_string?(value, other)
      end

      protected def get_value
        ptr = Pointer(LibC::Char).null
        get_value_ptr pointerof(ptr)
        ptr ? String.new(ptr) : ""
      end

      protected def set_value(value)
        case value
        when String
          # libgphoto2 copies the string, so no need to do it here
          set_value_ptr value.check_no_null_byte.to_unsafe
        when Symbol
          set_value value.to_s.capitalize
        when Number
          set_value value.to_s
        else
          raise ArgumentError.new \
            "Invalid value type, expected String | Symbol | Number, got #{value.class}"
        end
      end
    end
  end
end
