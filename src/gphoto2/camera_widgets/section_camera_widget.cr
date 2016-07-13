require "../camera_widget"

module GPhoto2
  class SectionCameraWidget < CameraWidget
    protected def get_value
      raise NotImplementedError.new
    end

    protected def set_value(value)
      raise NotImplementedError.new
    end

    # FIXME?
    private def free; end
  end
end
