require "./error"
require "./struct"

module GPhoto2
  abstract class CameraWidget
    macro inherited
      {% factory_id = @type.name.gsub(/^GPhoto2::/, "").gsub(/CameraWidget$/, "").underscore %}

      ::GPhoto2::CameraWidget.widgets[{{factory_id.stringify}}] = self

      class ::GPhoto2::CameraWidget
        def as_{{factory_id}}? : {{@type.name}}?
          self.as?({{@type.name}})
        end

        def as_{{factory_id}} : {{@type.name}}
          self.as({{@type.name}})
        end
      end
    end

    @@widgets = {} of String => CameraWidget.class

    def self.widgets : Hash(String, CameraWidget.class)
      @@widgets
    end

    def self.factory(ptr : LibGPhoto2::CameraWidget*, parent : CameraWidget? = nil) : CameraWidget
      type = ptr.value.type.to_s.downcase
      klass = @@widgets[type]
      klass.new(ptr, parent)
    end
  end

  abstract class CameraWidget
    include GPhoto2::Struct(LibGPhoto2::CameraWidget)

    getter parent : CameraWidget?

    def initialize(ptr : LibGPhoto2::CameraWidget*, @parent : CameraWidget? = nil)
      super ptr
    end

    def close : Void
      free
    end

    def readonly?
      get_readonly == 1
    end

    def type : LibGPhoto2::CameraWidgetType
      get_type
    end

    def id : LibC::Int
      get_id
    end

    def name : String
      get_name.not_nil!
    end

    def label : String
      get_label.not_nil!
    end

    def info : String
      get_info.not_nil!
    end

    def value
      get_value
    end

    def value=(value)
      set_value(value)
      value
    end

    def children : Array(CameraWidget)
      Array(CameraWidget).new(count_children) { |i| get_child(i) }
    end

    def flatten(map = {} of String => CameraWidget) : Hash(String, CameraWidget)
      case type
      when .window?, .section?
        children.each &.flatten(map)
      else
        map[name] = self
      end
      map
    end

    def to_s(io)
      io << value
    end

    def_equals type, name, value

    # Compares `#value` with given *other*.
    #
    # ```
    # camera[:whitebalance] == "Automatic"
    # camera[:shutterspeed] == 0.5
    # camera[:iso] == 400
    # ```
    def ==(other)
      self.to_s == other.to_s
    end

    # Compares `#value` with given `Symbol`.
    #
    # ```
    # camera[:whitebalance] == :automatic
    # ```
    def ==(other : Symbol)
      self.to_s == other.to_s.capitalize
    end

    # Compares `#value` with given `Regex`.
    #
    # ```
    # camera[:whitebalance] == /Automatic/
    # ```
    def ==(other : Regex)
      other === self.to_s
    end

    # Returns true if `#value` matches at least one element of the collection.
    #
    # ```
    # camera[:autoexposuremode].in? %w(Manual Bulb)
    # ```
    def in?(other)
      other.any? { |value| self == value }
    end

    # Returns true if `#value` is included in the *other* `Range`.
    #
    # ```
    # camera[:exposurecompensation].in? -1.6..0.6
    # camera[:aperture].in? 4..7.1
    # camera[:iso].in? 100..400
    # ```
    def in?(other : Range)
      value = self.to_s
      other.includes? (value =~ /^\-?\d+\.\d+$/) \
        ? value.to_f
        : value.to_i
    end

    protected abstract def get_value
    protected abstract def set_value(value)

    protected def get_value_ptr(ptr)
      GPhoto2.check! LibGPhoto2.gp_widget_get_value(self, ptr)
    end

    protected def set_value_ptr(ptr)
      GPhoto2.check! LibGPhoto2.gp_widget_set_value(self, ptr)
    end

    private def free
      GPhoto2.check! LibGPhoto2.gp_widget_free(self)
      self.ptr = nil
    end

    private def get_readonly
      GPhoto2.check! LibGPhoto2.gp_widget_get_readonly(self, out readonly)
      readonly
    end

    private def get_type
      GPhoto2.check! LibGPhoto2.gp_widget_get_type(self, out type)
      type
    end

    private def get_id
      GPhoto2.check! LibGPhoto2.gp_widget_get_id(self, out id)
      id
    end

    private def get_name
      GPhoto2.check! LibGPhoto2.gp_widget_get_name(self, out ptr)
      !ptr ? nil : String.new ptr
    end

    private def get_label
      GPhoto2.check! LibGPhoto2.gp_widget_get_label(self, out ptr)
      !ptr ? nil : String.new ptr
    end

    private def get_info
      GPhoto2.check! LibGPhoto2.gp_widget_get_info(self, out ptr)
      !ptr ? nil : String.new ptr
    end

    private def count_children
      GPhoto2.check! LibGPhoto2.gp_widget_count_children(self)
    end

    private def get_child(index)
      GPhoto2.check! LibGPhoto2.gp_widget_get_child(self, index, out widget)
      CameraWidget.factory(widget, self)
    end
  end
end
