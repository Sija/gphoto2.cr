require "./struct"
require "./camera/*"
require "./camera_widgets/*"

module GPhoto2
  class Camera
    include GPhoto2::Struct(LibGPhoto2::Camera)

    include Capture
    include Configuration
    include Event
    include Filesystem

    @model : String
    getter :model

    @port : String
    getter :port

    @context : Context?
    @abilities : CameraAbilities?
    @port_info : PortInfo?

    # Returns all available cameras.
    #
    # ```
    # cameras = GPhoto2::Camera.all # => [#<GPhoto2::Camera>, #<GPhoto2::Camera>, ...]
    # ```
    def self.all : Array(self)
      context = Context.new

      abilities = CameraAbilitiesList.new(context)
      cameras = abilities.detect

      entries = cameras.to_a.map do |entry|
        model, port = entry.name, entry.value
        Camera.new(model.not_nil!, port.not_nil!)
      end.to_a

      context.finalize
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
    #   camera.finalize
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
    def self.first(&block : self -> _) : Void
      camera = first
      autorelease(camera, block)
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
    #   camera.finalize
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
    def self.open(model : String, port : String, &block : self -> _) : Void
      camera = open(model, port)
      autorelease(camera, block)
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
    def autorelease(&block : self -> _) : Void
      self.class.autorelease(self, block)
    end

    def finalize : Void
      @context.try &.finalize
      unref if ptr?
    end

    def close : Void
      finalize
    end

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

    def context : Context
      @context ||= Context.new
    end

    # Check camera abilities (see `LibGPhoto2::CameraOperation`).
    #
    # ```
    # camera.can? :capture_image # => true
    # ```
    def can?(operation : Symbol)
      can? LibGPhoto2::CameraOperation.parse(operation.to_s)
    end

    protected def can?(operation : LibGPhoto2::CameraOperation)
      abilities.wrapped.operations.includes? operation
    end

    def_equals @model, @port

    # Ensures the given camera is finalized when passed a block.
    protected def self.autorelease(camera, block : self -> _) : Void
      begin
        block.call camera
      ensure
        camera.finalize
      end
    end

    private def init : Void
      new
      set_abilities CameraAbilities.find(@model)
      set_port_info PortInfo.find(@port)
    end

    private def new
      GPhoto2.check! LibGPhoto2.gp_camera_new(out ptr)
      self.ptr = ptr
    end

    private def _exit
      GPhoto2.check! LibGPhoto2.gp_camera_exit(self, context)
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
    end
  end
end
