require "./text_camera_widget"

module GPhoto2
  class RadioCameraWidget < TextCameraWidget
    def choices : Array(String?)
      choices = [] of String?
      count_choices.times.each { |i| choices << get_choice(i) }
      choices
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
