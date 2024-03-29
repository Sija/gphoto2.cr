module GPhoto2
  class Exception < ::Exception
  end

  class NotImplementedError < Exception
  end

  class NoDevicesError < Exception
    def initialize
      super("No devices detected")
    end
  end

  class Error < Exception
    getter code : Int32

    # Builds a new error from a GPhoto2 error code.
    def self.from_code(code : Int32) : Error
      message = GPhoto2.result_as_string(code)
      new(message, code)
    end

    def initialize(message : String?, @code : Int32)
      super(message)
    end

    def to_s(io : IO)
      if message
        io << message << ' '
      end
      io << '(' << code << ')'
    end
  end
end
