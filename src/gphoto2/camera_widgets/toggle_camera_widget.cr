require "../camera_widget"

module GPhoto2
  class ToggleCameraWidget < CameraWidget
    protected def get_value : Int32
      ptr = Pointer(LibC::Int).malloc
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_get_value(self, ptr)
      ptr.value
    end

    protected def set_value(value : Int32)
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_set_value(self, pointerof(value))
    end
  end
end
