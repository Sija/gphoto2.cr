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
      value = 0_f32
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_get_value(self, pointerof(value))
      value
    end

    protected def set_value(value)
      ptr = Pointer(LibC::Float).null
      ptr.value = value
      GPhoto2.check! FFI::LibGPhoto2.gp_widget_set_value(self, pointerof(ptr))
    end
  end
end
