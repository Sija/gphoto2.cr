require "./struct"

module GPhoto2
  class Context
    include Struct(FFI::LibGPhoto2::GPContext)

    def initialize
      new
    end

    def finalize
      unref
    end

    def close 
      finalize
    end

    private def new
      @ptr = FFI::LibGPhoto2.gp_context_new
    end

    private def unref
      FFI::LibGPhoto2.gp_context_unref(@ptr)
      @ptr = nil
    end
  end
end