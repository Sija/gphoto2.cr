@[Link("libgphoto2")]
lib LibGPhoto2
  #
  # Enums
  #

  enum CameraWidgetType
    Window
    Section
    Text
    Range
    Toggle
    Radio
    Menu
    Button
    Date
  end

  #
  # Aliases
  #

  alias CameraWidgetCallback = Camera*, CameraWidget*, GPContext* -> LibC::Int

  #
  # Structs
  #

  struct CameraWidget
    type : CameraWidgetType
    label : LibC::Char[256]
    info : LibC::Char[1024]
    name : LibC::Char[256]
    parent : CameraWidget*
    value_string : LibC::Char*
    value_int : LibC::Int
    value_float : LibC::Float
    choice : LibC::Char**
    choice_count : LibC::Int
    min : LibC::Float
    max : LibC::Float
    increment : LibC::Float
    children : CameraWidget**
    children_count : LibC::Int
    changed : LibC::Int
    readonly : LibC::Int
    ref_count : LibC::Int
    id : LibC::Int
    callback : CameraWidgetCallback
  end

  #
  # Functions
  #

  fun gp_widget_new(type : CameraWidgetType, label : LibC::Char*, widget : CameraWidget**) : LibC::Int
  fun gp_widget_free(widget : CameraWidget*) : LibC::Int
  fun gp_widget_ref(widget : CameraWidget*) : LibC::Int
  fun gp_widget_unref(widget : CameraWidget*) : LibC::Int

  fun gp_widget_append(widget : CameraWidget*, child : CameraWidget*) : LibC::Int
  fun gp_widget_prepend(widget : CameraWidget*, child : CameraWidget*) : LibC::Int
  fun gp_widget_count_children(widget : CameraWidget*) : LibC::Int

  fun gp_widget_get_child(widget : CameraWidget*, child_number : LibC::Int, child : CameraWidget**) : LibC::Int
  fun gp_widget_get_child_by_label(widget : CameraWidget*, label : LibC::Char*, child : CameraWidget**) : LibC::Int
  fun gp_widget_get_child_by_id(widget : CameraWidget*, id : LibC::Int, child : CameraWidget**) : LibC::Int
  fun gp_widget_get_child_by_name(widget : CameraWidget*, name : LibC::Char*, child : CameraWidget**) : LibC::Int

  fun gp_widget_get_root(widget : CameraWidget*, root : CameraWidget**) : LibC::Int
  fun gp_widget_get_parent(widget : CameraWidget*, parent : CameraWidget**) : LibC::Int

  fun gp_widget_set_value(widget : CameraWidget*, value : Void*) : LibC::Int
  fun gp_widget_get_value(widget : CameraWidget*, value : Void*) : LibC::Int

  fun gp_widget_set_name(widget : CameraWidget*, name : LibC::Char*) : LibC::Int
  fun gp_widget_get_name(widget : CameraWidget*, name : LibC::Char**) : LibC::Int

  fun gp_widget_set_info(widget : CameraWidget*, info : LibC::Char*) : LibC::Int
  fun gp_widget_get_info(widget : CameraWidget*, info : LibC::Char**) : LibC::Int

  fun gp_widget_get_id(widget : CameraWidget*, id : LibC::Int*) : LibC::Int
  fun gp_widget_get_type(widget : CameraWidget*, type : CameraWidgetType*) : LibC::Int
  fun gp_widget_get_label(widget : CameraWidget*, label : LibC::Char**) : LibC::Int

  fun gp_widget_set_range(range : CameraWidget*, low : LibC::Float, high : LibC::Float, increment : LibC::Float) : LibC::Int
  fun gp_widget_get_range(range : CameraWidget*, min : LibC::Float*, max : LibC::Float*, increment : LibC::Float*) : LibC::Int

  fun gp_widget_add_choice(widget : CameraWidget*, choice : LibC::Char*) : LibC::Int
  fun gp_widget_get_choice(widget : CameraWidget*, choice_number : LibC::Int, choice : LibC::Char**) : LibC::Int
  fun gp_widget_count_choices(widget : CameraWidget*) : LibC::Int

  fun gp_widget_changed(widget : CameraWidget*) : LibC::Int
  fun gp_widget_set_changed(widget : CameraWidget*, changed : LibC::Int) : LibC::Int

  fun gp_widget_set_readonly(widget : CameraWidget*, readonly : LibC::Int) : LibC::Int
  fun gp_widget_get_readonly(widget : CameraWidget*, readonly : LibC::Int*) : LibC::Int
end
