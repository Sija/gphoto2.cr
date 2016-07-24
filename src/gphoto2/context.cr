require "./struct"

module GPhoto2
  class Context
    include Struct(LibGPhoto2::GPContext)

    def initialize
      new
    end

    def finalize : Void
      unref
    end

    def close : Void
      finalize
    end

    private def new
      self.ptr = LibGPhoto2.gp_context_new
    end

    private def unref
      LibGPhoto2.gp_context_unref(self)
      self.ptr = nil
    end
  end
end
