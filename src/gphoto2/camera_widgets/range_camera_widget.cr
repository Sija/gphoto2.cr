require "../camera_widget"

module GPhoto2
  class RangeCameraWidget < CameraWidget
    # FIXME: Float => Int, hmmm...
    def range
      min, max, inc = get_range
      (min.to_i..max.to_i).step(inc.to_i).to_a
    end

    private def get_range
      min, max, inc = 0_f32, 0_f32, 0_f32
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_get_range(self, pointerof(min), pointerof(max), pointerof(inc))
      [min, max, inc]
    end

    protected def get_value
      ptr = Pointer(LibC::Float).malloc
      get_value_ptr ptr
      ptr.value
    end

    protected def set_value(value)
      case value
      when Float32
        ptr = Pointer(LibC::Float).malloc 1, value
        set_value_ptr ptr
      end
    end
  end
end
