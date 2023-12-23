require "./base"

module GPhoto2
  class CameraWidget
    class Toggle < Base
      protected def get_value
        ptr = Pointer(LibC::Int).malloc
        get_value_ptr ptr
        ptr.value == 1
      end

      protected def set_value(value)
        case value
        when Int
          ptr = Pointer(LibC::Int).malloc 1, LibC::Int.new(value.to_i32)
          set_value_ptr ptr
        when Bool
          set_value value ? 1 : 0
        when String
          set_value value.to_i32
        else
          raise ArgumentError.new \
            "Invalid value type, expected Int | Bool | String, got #{value.class}"
        end
      end
    end
  end
end
