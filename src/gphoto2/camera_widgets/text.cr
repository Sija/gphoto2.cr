require "./base"

module GPhoto2
  class CameraWidget
    class Text < Base
      protected def get_value
        ptr = Pointer(LibC::Char).null
        get_value_ptr pointerof(ptr)
        ptr ? String.new(ptr) : ""
      end

      protected def set_value(value)
        case value
        when String
          value.check_no_null_byte
          ptr = Pointer(LibC::Char).malloc(value.bytesize + 1)
          ptr.copy_from(value.to_unsafe, value.bytesize)
          set_value_ptr ptr
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
