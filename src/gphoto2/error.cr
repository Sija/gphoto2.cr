module GPhoto2
  class Exception < ::Exception; end

  class NoDevicesError < Exception
    def initialize
      super("No devices detected")
    end
  end

  class Error < Exception
    @code : Int32
    getter :code

    def initialize(message : String?, @code : Int32)
      super(message)
    end

    def to_s(io)
      io << message << ' ' << '(' << code << ')'
    end
  end
end
