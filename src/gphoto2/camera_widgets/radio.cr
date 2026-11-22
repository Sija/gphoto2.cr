require "./text"

module GPhoto2
  class CameraWidget
    class Radio < Text
      # Moves the cursor to the next choice.
      def >>(step : Int32) : String?
        move_by step
      end

      # Moves the cursor to the previous choice.
      def <<(step : Int32) : String?
        # Widened, since negating `Int32::MIN` would overflow
        move_cursor -step.to_i64
      end

      # Moves the cursor by the given *step*.
      #
      # Returns the new value, or `nil` if the cursor would end up
      # out of bounds (in which case the value is left unchanged).
      def move_by(step : Int32) : String?
        move_cursor step.to_i64
      end

      # Returns valid choices for a configuration widget.
      #
      # ```
      # camera[:whitebalance].as_radio.choices
      # # => ["Automatic", "Daylight", "Fluorescent", "Tungsten", ...]
      # ```
      def choices : Array(String)
        Array(String).new(count_choices) { |i| get_choice(i).not_nil! }
      end

      protected def set_value(value)
        case value
        when Enumerable, Regex
          match =
            case value
            in Enumerable
              # Candidates are tried in the given order (of preference),
              # rather than in the order of the choices
              valid_choices = choices
              value.find_value do |item|
                candidate = choice_value(item, valid_choices)
                candidate if candidate.try(&.in?(valid_choices))
              end
            in Regex
              choices.find &.matches?(value)
            end
          match || raise ArgumentError.new("No matching value found")
          super match
        when Number
          super choice_value(value, choices)
        else
          super
        end
      end

      # NOTE: Uses `Int64`, so that moving far out of bounds doesn't overflow.
      private def move_cursor(step : Int64) : String?
        choices = self.choices

        # Use the raw value, since `#value` returns `nil` for i.e. `None`
        return unless index = choices.index(get_value)

        next_index = index.to_i64 + step
        return unless 0 <= next_index < choices.size

        self.value = choices[next_index]
      end

      # Converts *value* to a choice, the same way `Text#value=` does,
      # except for numbers equal to one of the *choices* numerically
      # (i.e. `4.0` for `"4"`), which are converted to that choice.
      private def choice_value(value, choices : Array(String)) : String?
        case value
        when String then value
        when Symbol then value.to_s.capitalize
        when Number then numeric_choice(value, choices) || value.to_s
        end
      end

      private def numeric_choice(value : Number, choices : Array(String)) : String?
        choices.find { |choice| GPhoto2.number_string?(choice, value) }
      end

      private def count_choices
        GPhoto2.check! \
          LibGPhoto2.gp_widget_count_choices(self)
      end

      private def get_choice(i)
        ptr = Pointer(LibC::Char).null
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_choice(self, i, pointerof(ptr))
        String.new ptr if ptr
      end
    end
  end
end
