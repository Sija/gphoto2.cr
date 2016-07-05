require "../camera_widget"

module GPhoto2
  class TextCameraWidget < CameraWidget
    protected def get_value
      ptr = Pointer(LibC::Char).null
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_get_value(self, pointerof(ptr))
      !ptr ? nil : String.new ptr
    end

    protected def set_value(value : String)
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_set_value(self, pointerof(value))
    end
  end
end
