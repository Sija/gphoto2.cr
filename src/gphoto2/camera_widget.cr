module GPhoto2
  # Represents a widget.
  abstract class CameraWidget
    @@widgets = {} of String => Base.class

    # Returns the list of all available widgets.
    def self.widgets : Hash(String, Base.class)
      @@widgets
    end

    # Creates a new widget from the given pointer.
    def self.factory(ptr : LibGPhoto2::CameraWidget*, parent : Base? = nil) : Base
      type = ptr.value.type.to_s.downcase
      klass = @@widgets[type]
      klass.new(ptr, parent)
    end
  end
end

require "./camera_widgets/*"
