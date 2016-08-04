require "../camera_widget"

module GPhoto2
  class ToggleCameraWidget < CameraWidget
    protected def get_value
      ptr = Pointer(LibC::Int).malloc
      get_value_ptr ptr
      ptr.value
    end

    protected def set_value(value)
      case value
      when Int32
        ptr = Pointer(LibC::Int).malloc 1, value
        set_value_ptr ptr
      when Bool
        ptr = Pointer(LibC::Int).malloc 1, value ? 1 : 0
        set_value_ptr ptr
      when String
        ptr = Pointer(LibC::Int).malloc 1, value.to_i32
        set_value_ptr ptr
      else
        raise ArgumentError.new "Invalid value type, expected Int32 | Bool | String, got #{value.class}"
      end
    end
  end
end
