module GPhoto2
  class Error < Exception
    getter :code

    def initialize(message, @code : Int32)
      super(message)
    end

    def to_s(io)
      io << message << ' ' << '(' << code << ')'
    end
  end
end