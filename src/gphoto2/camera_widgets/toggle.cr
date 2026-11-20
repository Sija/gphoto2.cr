require "./base"

module GPhoto2
  class CameraWidget
    class Toggle < Base
      # Compares the toggle state with the given `Bool`.
      #
      # ```
      # camera[:autofocus] == true
      # ```
      def ==(other : Bool)
        get_value == (other ? 1 : 0)
      end

      protected def get_value
        value = uninitialized LibC::Int
        get_value_ptr pointerof(value)
        value.to_i32
      end

      protected def set_value(value)
        case value
        when Int
          # libgphoto2 stores the value as a C `int`
          unless LibC::Int::MIN <= value <= LibC::Int::MAX
            raise ArgumentError.new("Invalid value: #{value}")
          end
          int = LibC::Int.new(value)
          set_value_ptr pointerof(int)
        when Bool
          set_value value ? 1 : 0
        when String
          # Same values as accepted by the `gphoto2` CLI tool
          case value.strip.downcase
          when "true", "on", "yes"  then set_value true
          when "false", "off", "no" then set_value false
          else                           set_value value.to_i32
          end
        else
          raise ArgumentError.new \
            "Invalid value type, expected Int | Bool | String, got #{value.class}"
        end
      end
    end
  end
end
