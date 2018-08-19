require "./base"

module GPhoto2
  class CameraWidget
    class Date < Base
      protected def get_value
        ptr = Pointer(LibC::Int).malloc
        get_value_ptr ptr
        Time.epoch(ptr.value)
      end

      protected def set_value(value)
        case value
        when Time
          ptr = Pointer(LibC::Int).malloc 1, value.epoch.to_i32
          set_value_ptr ptr
        when Int
          set_value Time.epoch(value)
        when String
          set_value Time.parse!(value, "%F %T %z")
        else
          raise ArgumentError.new "Invalid value type, expected Time | Int | String, got #{value.class}"
        end
      end
    end
  end
end
