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
      def move_by(step : Int32) : String?
        choices = self.choices
        index = choices.index(self.value)
        if index
          next_value = choices[index + step]?
          if next_value
            self.value = next_value
          end
        end
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
            in Enumerable then choices.find &.in?(value)
            in Regex      then choices.find &.matches?(value)
            end
          match || raise ArgumentError.new("No matching value found")
          super match
        else
          super
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
