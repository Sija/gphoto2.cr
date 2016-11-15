module GPhoto2
  abstract class CameraWidget
    @@widgets = {} of String => Base.class

    def self.widgets : Hash(String, Base.class)
      @@widgets
    end

    def self.factory(ptr : LibGPhoto2::CameraWidget*, parent : Base? = nil) : Base
      type = ptr.value.type.to_s.downcase
      klass = @@widgets[type]
      klass.new(ptr, parent)
    end
  end
end

require "./camera_widgets/*"
