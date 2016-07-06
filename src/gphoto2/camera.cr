require "./struct"
require "./camera/*"
require "./camera_widgets/*"

module GPhoto2
  class Context; end
  class CameraAbilities; end
  class CameraAbilitiesList; end
  class PortInfo; end

  class Camera
    include GPhoto2::Struct(FFI::LibGPhoto2::Camera)

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

    # @example
    #   cameras = GPhoto2::Camera.all
    #   # => [#<GPhoto2::Camera>, #<GPhoto2::Camera>, ...]
    #
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

    # @example
    #   camera = GPhoto2::Camera.first
    #
    #   begin
    #     # ...
    #   ensure
    #     camera.finalize
    #   end
    #
    #   # Alternatively, pass a block, which will automatically close the camera.
    #   GPhoto2::Camera.first do |camera|
    #     # ...
    #   end
    #
    # @raise [RuntimeError] when no devices are detected
    def self.first : self
      cameras = all
      raise "no devices detected" if cameras.empty?
      cameras.first
    end

    def self.first(&block : self -> _) : Void
      camera = first
      autorelease(camera, block)
    end

    # @example
    #   model = "Nikon DSC D5100 (PTP mode)"
    #   port = "usb:250,006"
    #
    #   camera = GPhoto2::Camera.open(model, port)
    #
    #   begin
    #     # ...
    #   ensure
    #     camera.finalize
    #   end
    #
    #   # Alternatively, pass a block, which will automatically close the camera.
    #   GPhoto2::Camera.open(model, port) do |camera|
    #     # ...
    #   end
    #
    def self.open(model : String, port : String) : self
      camera = new(model, port)
    end

    def self.open(model : String, port : String, &block : self -> _) : Void
      camera = open(model, port)
      autorelease(camera, block)
    end

    # Filters devices by a given condition.
    #
    # Filter keys can be either `model` or `port`. Only the first filter is
    # used.
    #
    # @example
    #   # Find the cameras whose model names contain Nikon.
    #   cameras = GPhoto2::Camera.where(model: /nikon/i)
    #
    #   # Select a camera by its port.
    #   camera = GPhoto2::Camera.where(port: "usb:250,004").first
    #
    def self.where(model : String | Regex | Nil = nil, port : String | Regex | Nil = nil) : Array(self)
      all.select do |camera|
        (!model || camera.model.match model) && (!port || camera.port.match port)
      end
    end

    def initialize(@model, @port)
      # FIXME: should we make it lazy? see #ptr comments
      init
    end

    def finalize
      @context.try &.finalize
      @window.try &.finalize
      unref if ptr?
    end

    def close
      finalize
    end

    def exit
      _exit
    end

    # def ptr
    #   # FIXME: init invokes gp_* methods with self as a receiver
    #   # which in turn invokes self.ptr,
    #   # which finally leads to infinte recursion
    #   init unless ptr?
    #   super
    # end

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

    # @example
    #   camera.can? :capture_image
    #   # => true
    #
    def can?(operation : Symbol)
      can? FFI::LibGPhoto2::CameraOperation.parse operation.to_s
    end

    private def can?(operation : FFI::LibGPhoto2::CameraOperation)
      abilities.wrapped.operations.includes? operation
    end

    def_equals @model, @port

    # Ensures the given camera is finalized when passed a block.
    #
    private def self.autorelease(camera, block : self -> _) : Void
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
      GPhoto2.check! FFI::LibGPhoto2.gp_camera_new(out ptr)
      self.ptr = ptr
    end

    private def _exit
      GPhoto2.check! FFI::LibGPhoto2.gp_camera_exit(self, context)
    end

    private def set_port_info(port_info : PortInfo)
      GPhoto2.check! FFI::LibGPhoto2.gp_camera_set_port_info(self, port_info)
      @port_info = port_info
    end

    private def set_abilities(abilities : CameraAbilities)
      GPhoto2.check! FFI::LibGPhoto2.gp_camera_set_abilities(self, abilities.wrapped)
      @abilities = abilities
    end

    private def unref
      GPhoto2.check! FFI::LibGPhoto2.gp_camera_unref(self)
    end
  end
end
