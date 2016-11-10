require "../camera_widget"

module GPhoto2
  class RangeCameraWidget < CameraWidget
    def range : Array(LibC::Float)
      min, max, inc = get_range
      min.step(by: inc, limit: max).to_a
    end

    private def get_range
      min, max, inc = LibC::Float[3]
      GPhoto2.check! LibGPhoto2.gp_widget_get_range(self, pointerof(min), pointerof(max), pointerof(inc))
      {min, max, inc}
    end

    protected def get_value
      ptr = Pointer(LibC::Float).malloc
      get_value_ptr ptr
      ptr.value
    end

    protected def set_value(value)
      case value
      when Float
        ptr = Pointer(LibC::Float).malloc 1, value.to_f32
        set_value_ptr ptr
      when Int, String
        set_value value.to_f32
      else
        raise ArgumentError.new "Invalid value type, expected Float | Int | String, got #{value.class}"
      end
    end
  end
end
