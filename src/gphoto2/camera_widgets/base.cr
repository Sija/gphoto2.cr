require "../error"
require "../struct"

module GPhoto2
  class CameraWidget
    alias Type = LibGPhoto2::CameraWidgetType

    # Represents a widget.
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

      # Whether the widget tree memory is owned (and freed) by this widget.
      @owned : Bool

      # When *owned* is `nil`, root widgets (without *parent*) own their tree.
      #
      # Raises `ArgumentError` when *owned* is `true` for a child widget,
      # since its memory is owned (and freed) by its root widget.
      def initialize(ptr : LibGPhoto2::CameraWidget*, @parent = nil, *, owned : Bool? = nil)
        if owned && parent
          raise ArgumentError.new("Child widgets can't own their memory")
        end
        @owned = owned.nil? ? parent.nil? : owned
        super ptr
      end

      # Finalizes object by freeing allocated memory.
      def finalize
        close
      end

      # Frees allocated memory of the widget tree.
      #
      # NOTE: Child widgets are owned (and freed) by their root widget,
      # so calling this method on them does nothing.
      def close : Nil
        free if ptr? && @owned
      end

      # Raises if the widget, or (since child widgets point to the memory
      # owned by their root widget) any of its ancestors, has been closed.
      def to_unsafe : LibGPhoto2::CameraWidget*
        @parent.try &.to_unsafe
        @ptr || raise GPhoto2::Exception.new("Widget has been closed")
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
      def to_s(io : IO) : Nil
        # Widgets without value (i.e. `Window`) are represented as empty string
        io << value?
      end

      # Compares widget with another, based on `#type`, `#name` and `#value`.
      def ==(other : self)
        return true if same?(other)

        type == other.type &&
          name == other.name &&
          value? == other.value?
      end

      # NOTE: The (writable) `#value` is left out on purpose, so that
      # the hash of a widget doesn't change along with its value.
      def hash(hasher)
        hasher = type.hash(hasher)
        hasher = name.hash(hasher)
        hasher
      end

      # Compares `#value` with given *other* using `#to_s`.
      #
      # ```
      # camera[:whitebalance] == "Automatic"
      # camera[:shutterspeed] == 0.5
      # camera[:iso] == 400
      # ```
      def ==(other)
        # ameba:disable Style/RedundantSelf
        self.to_s == other.to_s
      end

      # Compares `#value` with given `Symbol`.
      #
      # ```
      # camera[:whitebalance] == :automatic
      # ```
      def ==(other : Symbol)
        # ameba:disable Style/RedundantSelf
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
      # Numeric ranges are compared against the numeric `#value`,
      # `Time` ranges against the `Time` value of `Date` widgets,
      # other ranges against the `#value` converted to a `String`.
      #
      # ```
      # camera[:exposurecompensation].in? -1.6..0.6
      # camera[:aperture].in? 4..7.1
      # camera[:iso].in? 100..400
      # camera[:datetime].in? 1.day.ago..Time.utc
      # ```
      def in?(other : ::Range(B, E)) : Bool forall B, E
        return false unless value = self.value

        {% if B < ::Number || E < ::Number %}
          !!((num_value = value.to_s.to_f?) && other.includes?(num_value))
        {% elsif B <= ::Time || E <= ::Time %}
          value.is_a?(::Time) && other.includes?(value)
        {% else %}
          other.includes?(value.to_s)
        {% end %}
      end

      # :nodoc:
      #
      # Returns the raw widget value, without treating any values as empty
      # (see `#value`), or `nil` for widgets without value.
      def raw_value
        get_value
      rescue NotImplementedError
      end

      # :nodoc:
      #
      # Sets the value of this widget to the raw value of the *other* one.
      def copy_value_from(other : Base) : Nil
        set_value(other.get_value)
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
