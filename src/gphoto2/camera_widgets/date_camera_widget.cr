require "../camera_widget"

module GPhoto2
  class DateCameraWidget < CameraWidget
    protected def get_value : Time
      ptr = Pointer(LibC::Int).malloc
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_get_value(self, ptr)
      Time.epoch(ptr.value).to_utc
    end

    protected def set_value(value : Time)
      value = value.epoch
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_set_value(self, pointerof(value))
    end
  end
end
