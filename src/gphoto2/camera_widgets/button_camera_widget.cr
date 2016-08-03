require "../camera_widget"

module GPhoto2
  class ButtonCameraWidget < CameraWidget
    protected def get_value
      raise NotImplementedError.new
    end

    protected def set_value(value)
      raise NotImplementedError.new
    end
  end
end
