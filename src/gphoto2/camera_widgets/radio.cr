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
        move_by -step
      end

      # Moves the cursor by the given *step*.
      #
      # Returns the new value, or `nil` if the cursor would end up
      # out of bounds (in which case the value is left unchanged).
      def move_by(step : Int32) : String?
        choices = self.choices
        # Use the raw value, since `#value` returns `nil` for i.e. `None`
        return unless index = choices.index(get_value)

        next_index = index + step
        return unless 0 <= next_index < choices.size

        self.value = choices[next_index]
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
            in Enumerable then choices.find { |choice| value.any? { |item| choice == choice_value(item) } }
            in Regex      then choices.find &.matches?(value)
            end
          match || raise ArgumentError.new("No matching value found")
          super match
        else
          super
        end
      end

      # Converts *value* to a choice, the same way `Text#value=` does.
      private def choice_value(value) : String?
        case value
        when String then value
        when Symbol then value.to_s.capitalize
        when Number then value.to_s
        end
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
