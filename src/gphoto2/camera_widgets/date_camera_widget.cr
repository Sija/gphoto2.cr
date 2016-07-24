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
      when String
        ptr = Pointer(LibC::Int).malloc 1, Time.parse(value, "%F %T %z").epoch.to_i32
        set_value_ptr ptr
      when Time
        ptr = Pointer(LibC::Int).malloc 1, value.epoch.to_i32
        set_value_ptr ptr
      when Int32
        ptr = Pointer(LibC::Int).malloc 1, value
        set_value_ptr ptr
      end
    end
  end
end
