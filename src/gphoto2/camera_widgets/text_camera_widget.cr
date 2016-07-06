require "../camera_widget"

module GPhoto2
  class TextCameraWidget < CameraWidget
    protected def get_value
      ptr = Pointer(LibC::Char).null
      get_value_ptr pointerof(ptr)
      !ptr ? nil : String.new ptr
    end

    protected def set_value(value)
      case value
      when String
        ptr = Pointer(LibC::Char).malloc(value.size)
        ptr.copy_from(value.to_unsafe, value.size)
        set_value_ptr ptr
      else
        if value.responds_to?(:to_s)
          value = value.to_s
          ptr = Pointer(LibC::Char).malloc(value.size)
          ptr.copy_from(value.to_unsafe, value.size)
          set_value_ptr ptr
        end
      end
    end
  end
end
