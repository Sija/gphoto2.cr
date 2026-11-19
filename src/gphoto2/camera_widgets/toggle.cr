require "./base"

module GPhoto2
  class CameraWidget
    class Toggle < Base
      protected def get_value
        value = uninitialized LibC::Int
        get_value_ptr pointerof(value)
        value.to_i32
      end

      protected def set_value(value)
        case value
        when Int
          int = LibC::Int.new(value)
          set_value_ptr pointerof(int)
        when Bool
          set_value value ? 1 : 0
        when String
          case value.downcase
          when "true"  then set_value true
          when "false" then set_value false
          else              set_value value.to_i32
          end
        else
          raise ArgumentError.new \
            "Invalid value type, expected Int | Bool | String, got #{value.class}"
        end
      end
    end
  end
end
