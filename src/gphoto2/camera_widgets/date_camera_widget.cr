require "../camera_widget"

module GPhoto2
  class DateCameraWidget < CameraWidget
    protected def get_value
      ptr = Pointer(LibC::Int).malloc
      get_value_ptr ptr
      Time.epoch(ptr.value).to_utc
    end

    protected def set_value(value)
      case value
      when Time
        ptr = Pointer(LibC::Int).malloc 1, value.epoch
        set_value_ptr ptr
      end
    end
  end
end
