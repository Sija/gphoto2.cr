require "spec"
require "file_utils"
require "../src/gphoto2"
require "./support/*"

module GPhoto2::SpecHelpers
  extend self

  # Model name of the libgphoto2 driver which exposes a local directory
  # as a camera filesystem, allowing to exercise the API without a device.
  DIRECTORY_CAMERA_MODEL = "Directory Browse"

  # Looking up the abilities loads all of the camera drivers, taking tens
  # of milliseconds, so it's done once only, instead of for every camera.
  DIRECTORY_CAMERA_ABILITIES = CameraAbilities.find(DIRECTORY_CAMERA_MODEL)

  # Creates a temporary directory populated with fixture files:
  #
  # ```text
  # DCIM/a.jpg     -> "hello"
  # DCIM/sub/b.jpg -> "xyz"
  # ```
  def with_fixture_dir(&)
    dir = File.tempname("gphoto2-spec")

    Dir.mkdir_p(File.join(dir, "DCIM", "sub"))
    File.write(File.join(dir, "DCIM", "a.jpg"), "hello")
    File.write(File.join(dir, "DCIM", "sub", "b.jpg"), "xyz")

    begin
      yield dir
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  # Yields a `Camera` backed by the "Directory Browse" driver,
  # pointing at a fresh fixture directory (see `#with_fixture_dir`).
  def with_directory_camera(&)
    with_fixture_dir do |dir|
      camera = Camera.new(DIRECTORY_CAMERA_MODEL, "disk:#{dir}")
      camera.abilities = DIRECTORY_CAMERA_ABILITIES
      begin
        yield camera, dir
      ensure
        camera.close
      end
    end
  end

  # Builds a standalone widget of the given *type*.
  def build_widget(type : CameraWidget::Type, name : String = type.to_s.downcase) : CameraWidget::Base
    CameraWidget.factory(build_widget_ptr(type, name))
  end

  # Builds an unmanaged widget of the given *type*, i.e. to be appended
  # to another widget (which takes over its ownership).
  def build_widget_ptr(type : CameraWidget::Type, name : String = type.to_s.downcase) : LibGPhoto2::CameraWidget*
    GPhoto2.check! LibGPhoto2.gp_widget_new(type, name, out ptr)
    GPhoto2.check! LibGPhoto2.gp_widget_set_name(ptr, name)
    ptr
  end

  # Builds a radio widget with the given *choices*.
  def build_radio(choices : Enumerable(String), name : String = "radio") : CameraWidget::Radio
    widget = build_widget(:radio, name).as_radio
    choices.each do |choice|
      GPhoto2.check! LibGPhoto2.gp_widget_add_choice(widget, choice)
    end
    widget
  end

  # Builds a range widget with the given bounds.
  def build_range(min : Float32, max : Float32, step : Float32, name : String = "range") : CameraWidget::Range
    widget = build_widget(:range, name).as_range
    GPhoto2.check! LibGPhoto2.gp_widget_set_range(widget, min, max, step)
    widget
  end
end

# :nodoc:
class GPhoto2::Camera
  # Made public, so that the specs can reuse the abilities looked up once
  # (see `GPhoto2::SpecHelpers::DIRECTORY_CAMERA_ABILITIES`).
  setter abilities : CameraAbilities?
end

include GPhoto2::SpecHelpers
