require "../camera_widget"

module GPhoto2
  class ToggleCameraWidget < CameraWidget
    protected def get_value
      value = 0
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_get_value(self, pointerof(value))
      value == 1
    end

    protected def set_value(value : Bool)
      # FIXME: ?
      ptr = Pointer(LibC::Int).null # malloc?
      ptr.value = value ? 1 : 0
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_set_value(self, pointerof(value))
    end
  end
end
