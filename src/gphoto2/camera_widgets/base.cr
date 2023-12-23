require "../error"
require "../struct"

module GPhoto2
  class CameraWidget
    alias Type = LibGPhoto2::CameraWidgetType

    abstract class Base
      include GPhoto2::Struct(LibGPhoto2::CameraWidget)

      # Returns parent widget, `nil` otherwise.
      getter parent : Base?

      macro inherited
        {% unless @type.abstract? %}
          {% factory_id = @type.name.gsub(/^(.+)::(.+)$/, "\\2").underscore %}

          ::GPhoto2::CameraWidget.widgets[{{ factory_id.stringify }}] = self

          class ::GPhoto2::CameraWidget::Base
            # Returns widget as `{{ factory_id.camelcase }}`, `nil` otherwise.
            def as_{{ factory_id }}? : {{ @type.name }}?
              self.as?({{ @type.name }})
            end

            # Returns widget as `{{ factory_id.camelcase }}`, raises otherwise.
            def as_{{ factory_id }} : {{ @type.name }}
              self.as({{ @type.name }})
            end
          end
        {% end %}
      end

      def initialize(ptr : LibGPhoto2::CameraWidget*, @parent = nil)
        super ptr
      end

      def close : Nil
        free if ptr?
      end

      # Returns `true` if the widget has readonly flag set.
      getter? readonly : Bool do
        get_readonly == 1
      end

      # Returns type of the widget.
      getter type : Type do
        get_type
      end

      # Returns widget numerical id.
      getter id : Int32 do
        get_id.to_i32
      end

      # Returns widget name.
      getter name : String do
        get_name.not_nil!
      end

      # Returns widget label.
      getter label : String do
        get_label.not_nil!
      end

      # Returns widget info if set.
      getter info : String do
        get_info.not_nil!
      end

      private EMPTY_VALUES = {nil, "none"}

      # Returns widget `value` unless it's empty or is known to be
      # an empty string, like `none` or raises `NotImplementedError`.
      def value?
        value
      rescue NotImplementedError
      end

      # Returns widget value.
      def value
        get_value.tap do |value|
          return if value.to_s.presence.try(&.downcase).in?(EMPTY_VALUES)
        end
      end

      # Sets widget value.
      def value=(value)
        set_value(value)
        value
      end

      # Returns widget children.
      def children : Array(Base)
        Array(Base).new(count_children) { |i| get_child(i) }
      end

      # Returns flat structure of widget `#children`.
      def flatten(map = {} of String => Base) : Hash(String, Base)
        case type
        when .window?, .section?
          children.each &.flatten(map)
        else
          map[name] = self
        end
        map
      end

      # Returns string representation of the widget `#value`.
      #
      # ```
      # puts camera[:whitebalance].to_s # => "Automatic"
      # ```
      def to_s(io : IO)
        io << value
      end

      # Compares widget with another, based on `#type`, `#name` and `#value`.
      def_equals type, name, value

      # Compares `#value` with given *other* using `#to_s`.
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

      # Returns `true` if `#value` matches at least one element of the collection.
      #
      # ```
      # camera[:autoexposuremode].in? %w(Manual Bulb)
      # ```
      def in?(other : Enumerable)
        other.any? { |value| self == value }
      end

      # Returns `true` if `#value` is included in the *other* `::Range`.
      #
      # ```
      # camera[:exposurecompensation].in? -1.6..0.6
      # camera[:aperture].in? 4..7.1
      # camera[:iso].in? 100..400
      # ```
      def in?(other : ::Range)
        return false unless value = self.value

        if other.begin.class <= Number || other.end.class <= Number
          !!((num_value = value.to_s.to_f?) && other.includes?(num_value))
        else
          other.includes?(value)
        end
      end

      protected abstract def get_value
      protected abstract def set_value(value)

      protected def get_value_ptr(ptr)
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_value(self, ptr)
      end

      protected def set_value_ptr(ptr)
        GPhoto2.check! \
          LibGPhoto2.gp_widget_set_value(self, ptr)
      end

      private def free
        GPhoto2.check! \
          LibGPhoto2.gp_widget_free(self)
        self.ptr = nil
      end

      private def get_readonly
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_readonly(self, out readonly)
        readonly
      end

      private def get_type
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_type(self, out type)
        type
      end

      private def get_id
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_id(self, out id)
        id
      end

      private def get_name
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_name(self, out ptr)
        String.new ptr if ptr
      end

      private def get_label
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_label(self, out ptr)
        String.new ptr if ptr
      end

      private def get_info
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_info(self, out ptr)
        String.new ptr if ptr
      end

      private def count_children
        GPhoto2.check! \
          LibGPhoto2.gp_widget_count_children(self)
      end

      private def get_child(index)
        GPhoto2.check! \
          LibGPhoto2.gp_widget_get_child(self, index, out widget)
        CameraWidget.factory(widget, self)
      end
    end
  end
end
