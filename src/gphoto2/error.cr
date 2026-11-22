module GPhoto2
  class Exception < ::Exception
  end

  class NotImplementedError < Exception
  end

  class NoDevicesError < Exception
    # Creates an error with the default message.
    def initialize
      super("No devices detected")
    end
  end

  class Error < Exception
    # Returns the libgphoto2 error code (i.e. `LibGPhoto2::GP_ERROR_IO`).
    getter code : Int32

    # Builds a new error from a GPhoto2 error code.
    def self.from_code(code : Int32) : Error
      message = GPhoto2.result_as_string(code)
      new(message, code)
    end

    # Creates an error with the given *message* and libgphoto2 error *code*.
    def initialize(message : String?, @code : Int32)
      super(message)
    end

    # Returns the message followed by the error code, i.e. `I/O problem (-7)`.
    def to_s(io : IO)
      if message = self.message.presence
        io << message << ' '
      end
      io << '(' << code << ')'
    end
  end
end
