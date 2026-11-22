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

      # Compares the toggle state with the given `Symbol`, naming
      # one of the states accepted by `#value=` (i.e. `:on`, `:off`).
      #
      # ```
      # camera[:autofocus] == :on
      # ```
      def ==(other : Symbol) : Bool
        state = parse_state(other.to_s)
        !state.nil? && self == state
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
          state = parse_state(value)
          set_value state.nil? ? value.to_i32 : state
        when Symbol
          state = parse_state(value.to_s)
          if state.nil?
            raise ArgumentError.new("Invalid value: #{value.inspect}")
          end
          set_value state
        else
          raise ArgumentError.new \
            "Invalid value type, expected Int | Bool | String | Symbol, got #{value.class}"
        end
      end

      # Returns the state named by *value*, or `nil` if there's none.
      private def parse_state(value : String) : Bool?
        # Same values as accepted by the `gphoto2` CLI tool
        case value.strip.downcase
        when "true", "on", "yes"  then true
        when "false", "off", "no" then false
        end
      end
    end
  end
end
