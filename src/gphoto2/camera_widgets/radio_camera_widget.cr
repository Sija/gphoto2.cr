require "./text_camera_widget"

module GPhoto2
  class RadioCameraWidget < TextCameraWidget
    def >>(step : Int32) : String?
      move_by step
    end

    def <<(step : Int32) : String?
      move_by -step
    end

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

    def choices : Array(String?)
      choices = [] of String?
      count_choices.times.each { |i| choices << get_choice(i) }
      choices
    end

    protected def set_value(value)
      case value
      when Regex
        matches = choices.select &.try &.match(value)
        super matches.first
      else
        super
      end
    end

    private def count_choices
      GPhoto2.check! LibGPhoto2.gp_widget_count_choices(self)
    end

    private def get_choice(i)
      ptr = Pointer(LibC::Char).null
      GPhoto2.check! LibGPhoto2.gp_widget_get_choice(self, i, pointerof(ptr))
      !ptr ? nil : String.new ptr
    end
  end
end
