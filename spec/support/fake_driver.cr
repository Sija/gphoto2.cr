# Simulates camera driver features not provided by the "Directory Browse"
# driver (configuration, capture, events, ...), by replacing the driver
# functions of an initialized camera with stubs backed by `FakeDriver` state.
module GPhoto2::FakeDriver
  extend self

  # Configuration widget definition.
  record Setting,
    type : CameraWidget::Type,
    value : String = "",
    choices : Array(String) = [] of String,
    readonly : Bool = false

  # Event definition, *path* is used for file/folder events.
  record FakeEvent,
    type : CameraEvent::Type,
    path : String? = nil,
    # Whether to leave the event data untouched (allowed by libgphoto2).
    untouched_data : Bool = false

  class_getter settings = {} of String => Setting
  class_getter events = Deque(FakeEvent).new
  # Path of the captured file, `nil` leaves it untouched.
  class_property capture_path : String? = "/DCIM/a.jpg"
  class_property preview_data = "preview"
  # Text returned by the info functions, `nil` leaves it untouched.
  class_property text : String? = "fake text"
  class_property? fail_set_config = false
  # Number of the upcoming `set_config` calls to fail.
  class_property set_config_failures = 0
  class_getter calls = Hash(Symbol, Int32).new(0)
  # Timeout (in milliseconds) received by the last `wait_for_event` call.
  class_property last_timeout : Int32?

  def reset : Nil
    settings.clear
    events.clear
    calls.clear

    self.capture_path = "/DCIM/a.jpg"
    self.preview_data = "preview"
    self.text = "fake text"
    self.fail_set_config = false
    self.set_config_failures = 0
    self.last_timeout = nil
  end

  # Installs stubs on the given *camera*.
  def install(camera : Camera) : Nil
    # Make sure the driver is initialized, so it doesn't override our stubs.
    camera.filesystem.folders

    functions = camera.wrapped.functions
    funcs = functions.value

    funcs.get_config = ->(_camera : LibGPhoto2::Camera*, window : LibGPhoto2::CameraWidget**, _context : LibGPhoto2::GPContext*) {
      FakeDriver.calls[:get_config] += 1
      window.value = FakeDriver.build_window
      LibGPhoto2::GP_OK
    }

    funcs.set_config = ->(_camera : LibGPhoto2::Camera*, window : LibGPhoto2::CameraWidget*, _context : LibGPhoto2::GPContext*) {
      FakeDriver.calls[:set_config] += 1
      if FakeDriver.fail_set_config?
        LibGPhoto2::GP_ERROR_IO
      elsif FakeDriver.set_config_failures > 0
        FakeDriver.set_config_failures -= 1
        LibGPhoto2::GP_ERROR_IO
      else
        FakeDriver.store_window(window)
        LibGPhoto2::GP_OK
      end
    }

    funcs.capture = ->(_camera : LibGPhoto2::Camera*, _type : LibGPhoto2::CameraCaptureType, path : LibGPhoto2::CameraFilePath*, _context : LibGPhoto2::GPContext*) {
      FakeDriver.calls[:capture] += 1
      if capture_path = FakeDriver.capture_path
        path.value = FakeDriver.build_path(capture_path)
      end
      LibGPhoto2::GP_OK
    }

    funcs.trigger_capture = ->(_camera : LibGPhoto2::Camera*, _context : LibGPhoto2::GPContext*) {
      FakeDriver.calls[:trigger_capture] += 1
      LibGPhoto2::GP_OK
    }

    funcs.capture_preview = ->(_camera : LibGPhoto2::Camera*, file : LibGPhoto2::CameraFile*, _context : LibGPhoto2::GPContext*) {
      FakeDriver.calls[:capture_preview] += 1
      data = FakeDriver.preview_data
      buffer = LibC.malloc(data.bytesize).as(UInt8*)
      buffer.copy_from(data.to_unsafe, data.bytesize)
      LibGPhoto2.gp_file_set_data_and_size(file, buffer, data.bytesize)
    }

    funcs.wait_for_event = ->(_camera : LibGPhoto2::Camera*, timeout : LibC::Int, type : LibGPhoto2::CameraEventType*, data : Void**, _context : LibGPhoto2::GPContext*) {
      FakeDriver.calls[:wait_for_event] += 1
      FakeDriver.last_timeout = timeout
      event = FakeDriver.events.shift? || FakeEvent.new(:timeout)
      type.value = event.type
      unless event.untouched_data
        data.value =
          if path = event.path
            ptr = LibC.malloc(sizeof(LibGPhoto2::CameraFilePath)).as(LibGPhoto2::CameraFilePath*)
            ptr.value = FakeDriver.build_path(path)
            ptr.as(Void*)
          else
            Pointer(Void).null
          end
      end
      LibGPhoto2::GP_OK
    }

    {% for name in %w[summary manual about] %}
      funcs.{{ name.id }} = ->(_camera : LibGPhoto2::Camera*, text : LibGPhoto2::CameraText*, _context : LibGPhoto2::GPContext*) {
        FakeDriver.write_text(text)
        LibGPhoto2::GP_OK
      }
    {% end %}

    functions.value = funcs
  end

  # :nodoc:
  def build_window : LibGPhoto2::CameraWidget*
    LibGPhoto2.gp_widget_new(CameraWidget::Type::Window, "Camera", out window)
    LibGPhoto2.gp_widget_set_name(window, "main")
    LibGPhoto2.gp_widget_new(CameraWidget::Type::Section, "Settings", out section)
    LibGPhoto2.gp_widget_set_name(section, "settings")
    LibGPhoto2.gp_widget_append(window, section)

    settings.each do |name, setting|
      LibGPhoto2.gp_widget_new(setting.type, name, out widget)
      LibGPhoto2.gp_widget_set_name(widget, name)
      LibGPhoto2.gp_widget_set_readonly(widget, setting.readonly ? 1 : 0)
      setting.choices.each do |choice|
        LibGPhoto2.gp_widget_add_choice(widget, choice)
      end
      CameraWidget.factory(widget, owned: false).value = setting.value unless setting.value.empty?
      LibGPhoto2.gp_widget_set_changed(widget, 0)
      LibGPhoto2.gp_widget_append(section, widget)
    end
    window
  end

  # :nodoc:
  def store_window(window : LibGPhoto2::CameraWidget*) : Nil
    CameraWidget.factory(window, owned: false).flatten.each do |name, widget|
      next unless setting = settings[name]?
      next if setting.readonly
      settings[name] = setting.copy_with(value: raw_value(widget))
    end
  end

  private def raw_value(widget) : String
    case widget
    when CameraWidget::Date
      # Stored in a format accepted by `Date#value=` (see `#build_window`)
      widget.value.as(Time).to_rfc3339
    else
      widget.raw_value.to_s
    end
  end

  # :nodoc:
  def build_path(path : String) : LibGPhoto2::CameraFilePath
    # Split at the last separator, so that i.e. "/DCIM/" gives an empty name
    if index = path.rindex('/')
      folder, name = path[0, index].presence || "/", path[(index + 1)..]
    else
      folder, name = "/", path
    end

    file_path = LibGPhoto2::CameraFilePath.new

    # Both fields are fixed-size, null-terminated strings. Since it's called
    # from within the stubbed C functions, raising is not an option.
    if name.bytesize >= file_path.name.size || folder.bytesize >= file_path.folder.size
      abort "FakeDriver: path too long: #{path.inspect}"
    end

    file_path.name.to_unsafe.copy_from(name.to_unsafe, name.bytesize)
    file_path.folder.to_unsafe.copy_from(folder.to_unsafe, folder.bytesize)
    file_path
  end

  # :nodoc:
  def write_text(text : LibGPhoto2::CameraText*) : Nil
    return unless value = self.text

    # The text is a fixed-size, null-terminated string. Since it's called
    # from within the stubbed C functions, raising is not an option.
    if value.bytesize >= sizeof(LibGPhoto2::CameraText)
      abort "FakeDriver: text too long (#{value.bytesize} bytes)"
    end

    # `text` is the only field of the struct
    buffer = text.as(LibC::Char*)
    buffer.copy_from(value.to_unsafe, value.bytesize)
    buffer[value.bytesize] = 0_u8
  end
end

module GPhoto2::SpecHelpers
  # Yields a camera with stubbed driver functions (see `FakeDriver`).
  def with_fake_camera(&)
    FakeDriver.reset

    with_directory_camera do |camera, dir|
      FakeDriver.install(camera)
      yield camera, dir
    end
  end
end
