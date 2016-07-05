require "../camera_widget"

module GPhoto2
  class DateCameraWidget < CameraWidget
    protected def get_value
      value = 0
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_get_value(self, pointerof(value))
      Time.epoch(value).to_utc
    end

    protected def set_value(value : Time)
      value = value.epoch
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_set_value(self, pointerof(value))
    end
  end
end
