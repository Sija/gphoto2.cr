require "./base"

module GPhoto2
  class CameraWidget
    class Button < Base
      protected def get_value
        ptr = Pointer(LibGPhoto2::CameraWidgetCallback).null
        get_value_ptr pointerof(ptr)
        !ptr ? nil : ptr.value
      end

      protected def set_value(value)
        raise NotImplementedError.new
      end
    end
  end
end
