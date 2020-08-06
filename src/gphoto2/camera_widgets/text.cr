require "./base"

module GPhoto2
  class CameraWidget
    class Text < Base
      protected def get_value
        ptr = Pointer(LibC::Char).null
        get_value_ptr pointerof(ptr)
        String.new ptr if ptr
      end

      protected def set_value(value)
        case value
        when String
          ptr = Pointer(LibC::Char).malloc(value.size)
          ptr.copy_from(value.to_unsafe, value.size)
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
