module GPhoto2
  class Error < Exception
    @code : Int32
    getter :code

    def initialize(message, @code)
      super(message)
    end

    def to_s(io)
      io << message << ' ' << '(' << code << ')'
    end
  end
end