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

    def self.from_code(code : Int32) : Error
      message = GPhoto2.result_as_string(code)
      new(message, code)
    end

    def initialize(message : String?, @code : Int32)
      super(message)
    end

    def to_s(io)
      if message
        io << message << ' '
      end
      io << '(' << code << ')'
    end
  end
end
