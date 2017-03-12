require "./struct"
require "./camera/*"

module GPhoto2
  class Camera
    include GPhoto2::Struct(LibGPhoto2::Camera)

    include Capture
    include Configuration
    include Event
    include Filesystem
    include Info

    getter model : String
    getter port : String

    protected setter abilities : CameraAbilities?
    protected setter port_info : PortInfo?

    # Returns all available cameras.
    #
    # ```
    # cameras = GPhoto2::Camera.all # => [#<GPhoto2::Camera>, #<GPhoto2::Camera>, ...]
    # ```
    def self.all : Array(self)
      context = Context.new

      port_info_list = PortInfoList.new
      abilities_list = CameraAbilitiesList.new(context, port_info_list)
      cameras = abilities_list.detect

      entries = cameras.to_a.map do |entry|
        camera = Camera.new(model: entry.name, port: entry.value)

        # See: `CameraAbilities.find`
        if abilities = abilities_list[camera.model]
          camera.abilities = abilities
        end
        # See: `PortInfo.find`
        if port_info = port_info_list[camera.port]
          camera.port_info = port_info
        end

        camera
      end

      context.close
      entries
    end

    # Returns first available camera or raises `NoDevicesError`
    # when no devices are detected.
    #
    # ```
    # camera = GPhoto2::Camera.first
    #
    # begin
    #   # ...
    # ensure
    #   camera.close
    # end
    # ```
    def self.first : self
      cameras = all
      raise NoDevicesError.new if cameras.empty?
      cameras.first
    end

    # Pass a block to automatically close the camera.
    #
    # ```
    # GPhoto2::Camera.first do |camera|
    #   # ...
    # end
    # ```
    def self.first : Void
      camera = first
      autorelease(camera) { |camera| yield camera }
    end

    # ```
    # model = "Nikon DSC D5100 (PTP mode)"
    # port = "usb:250,006"
    #
    # camera = GPhoto2::Camera.open(model, port)
    #
    # begin
    #   # ...
    # ensure
    #   camera.close
    # end
    # ```
    def self.open(model : String, port : String) : self
      camera = new(model, port)
    end

    # Pass a block to automatically close the camera.
    #
    # ```
    # GPhoto2::Camera.open(model, port) do |camera|
    #   # ...
    # end
    # ```
    def self.open(model : String, port : String) : Void
      camera = open(model, port)
      autorelease(camera) { |camera| yield camera }
    end

    # Filters devices by a given condition.
    #
    # Filter keys can be either *model* or *port*. Only the first filter is
    # used.
    #
    # ```
    # # Find the cameras whose model names contain Nikon.
    # cameras = GPhoto2::Camera.where(model: /nikon/i)
    #
    # # Select a camera by its port.
    # camera = GPhoto2::Camera.where(port: "usb:250,004").first
    # ```
    def self.where(model : String | Regex = nil, port : String | Regex = nil) : Array(self)
      all.select do |camera|
        (!model || camera.model.match model) && (!port || camera.port.match port)
      end
    end

    def initialize(@model : String, @port : String); end

    def ptr
      init unless ptr?
      super
    end

    # Ensures the camera is finalized when passed a block.
    #
    # ```
    # # Find the cameras whose model names contain Nikon.
    # cameras = GPhoto2::Camera.where(model: /nikon/i)
    #
    # # Pass a block, which will automatically close the camera.
    # cameras.first.autorelease do |camera|
    #   # ...
    # end
    # ```
    def autorelease : Void
      self.class.autorelease(self) { |camera| yield camera }
    end

    def close : Void
      @context.try &.close
      @window.try &.close
      unref if ptr?
    end

    # Closes a connection to the camera and therefore gives other application the possibility to access the camera, too.
    # It is recommended that you call this function when you currently don't need the camera.
    #
    # NOTE: The camera will get reinitialized if you try to access the camera again.
    def exit : Void
      _exit
    end

    def abilities : CameraAbilities
      init unless @abilities
      @abilities.not_nil!
    end

    def port_info : PortInfo
      init unless @port_info
      @port_info.not_nil!
    end

    getter context : Context { Context.new }

    # Yields opened instance of `Port` with already associated camera's `PortInfo`.
    # Port is automatically closed on block exit/exception.
    #
    # To reset given camera's port you can do:
    #
    # ```
    # camera.with_port do |port|
    #   camera.exit
    #   port.reset
    # end
    # ```
    def with_port : Void
      port = Port.new
      port.info = port_info
      port.open
      begin
        yield port, self
      ensure
        port.close
      end
    end

    # Check camera abilities (see `LibGPhoto2::CameraOperation`).
    #
    # ```
    # camera.can? :capture_image # => true
    # ```
    #
    # See also: `LibGPhoto2::CameraOperation`
    def can?(operation : Symbol)
      can? LibGPhoto2::CameraOperation.parse(operation.to_s)
    end

    # :nodoc:
    def can?(operation : LibGPhoto2::CameraOperation)
      abilities.operations.includes? operation
    end

    def_equals @model, @port

    # Ensures the given camera is finalized when passed a block.
    protected def self.autorelease(camera) : Void
      begin
        yield camera
      ensure
        camera.close
      end
    end

    private def init : Void
      new
      set_abilities @abilities || CameraAbilities.find(@model)
      set_port_info @port_info || PortInfo.find(@port)
    end

    private def new
      GPhoto2.check! LibGPhoto2.gp_camera_new(out ptr)
      self.ptr = ptr
    end

    private def _exit
      context.check! LibGPhoto2.gp_camera_exit(self, context)
    end

    private def set_port_info(port_info : PortInfo)
      # Need to use `@ptr` instead of `self`, since we call
      # `#init` inside of overridden `#ptr` method.
      GPhoto2.check! LibGPhoto2.gp_camera_set_port_info(@ptr, port_info)
      @port_info = port_info
    end

    private def set_abilities(abilities : CameraAbilities)
      # Need to use `@ptr` instead of `self`, since we call
      # `#init` inside of overridden `#ptr` method.
      GPhoto2.check! LibGPhoto2.gp_camera_set_abilities(@ptr, abilities.wrapped)
      @abilities = abilities
    end

    private def unref
      GPhoto2.check! LibGPhoto2.gp_camera_unref(self)
      self.ptr = nil
    end
  end
end
