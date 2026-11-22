require "./base"

module GPhoto2
  class CameraWidget
    class Date < Base
      # Compares the `#value` with the given time, regardless of its location
      # (unlike `#to_s`, which includes it).
      #
      # ```
      # camera[:datetime] == Time.local(2020, 1, 2, 3, 4, 5)
      # ```
      def ==(other : Time) : Bool
        get_value == other
      end

      protected def get_value
        value = uninitialized LibC::Int
        get_value_ptr pointerof(value)
        Time.unix(value)
      end

      protected def set_value(value)
        case value
        when Time
          # libgphoto2 stores the value as a (32-bit) C `int`
          unix = LibC::Int.new!(value.to_unix)
          unless unix == value.to_unix
            raise ArgumentError.new("Time out of range: #{value}")
          end
          set_value_ptr pointerof(unix)
        when Int
          # Checked upfront, since `Time.unix` raises other errors
          # (i.e. `OverflowError`) for the values out of its own range
          unless LibC::Int::MIN <= value <= LibC::Int::MAX
            raise ArgumentError.new("Time out of range: #{value}")
          end
          set_value Time.unix(value.to_i64)
        when String
          set_value parse_time(value)
        else
          raise ArgumentError.new \
            "Invalid value type, expected Time | Int | String, got #{value.class}"
        end
      end

      # Parses *value* in either `Time#to_s` or ISO 8601 format.
      private def parse_time(value : String) : Time
        Time.parse!(value, "%F %T %z")
      rescue Time::Format::Error
        Time::Format::ISO_8601_DATE_TIME.parse(value)
      end
    end
  end
end
