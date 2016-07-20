require "../camera_widget"

module GPhoto2
  class RangeCameraWidget < CameraWidget
    def range
      # TODO: remove it once Range start accepting float as type
      # min, max, inc = get_range
      # (min..max).step(inc).to_a
      min, max, inc = get_range
      arr = [] of Float32
      i = min
      while i <= max
        arr << i.to_f32
        i += inc
      end
      arr
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
      when Float32
        ptr = Pointer(LibC::Float).malloc 1, value.to_f32
        set_value_ptr ptr
      end
    end
  end
end
