require "./struct"
require "./context/*"

module GPhoto2
  class Context
    include Struct(LibGPhoto2::GPContext)

    include Callbacks

    def initialize
      new
      super
    end

    def close : Void
      unref
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
