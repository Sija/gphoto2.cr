module GPhoto2
  # Represents a widget.
  abstract class CameraWidget
    @@widgets = {} of String => Base.class

    # Returns the list of all available widgets.
    def self.widgets : Hash(String, Base.class)
      @@widgets
    end

    # Creates a new widget from the given pointer.
    #
    # See `Base.new` for the meaning of *owned*.
    def self.factory(ptr : LibGPhoto2::CameraWidget*, parent : Base? = nil, *, owned : Bool? = nil) : Base
      # `CameraWidget` struct is opaque, so its fields shouldn't be accessed directly
      GPhoto2.check! LibGPhoto2.gp_widget_get_type(ptr, out type)
      klass = @@widgets[type.to_s.downcase]
      klass.new(ptr, parent, owned: owned)
    end
  end
end

require "./camera_widgets/*"
