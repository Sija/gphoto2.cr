require "./struct"
require "./context/*"

module GPhoto2
  class Context
    include Struct(LibGPhoto2::GPContext)

    include Callbacks

    # NOTE: allocates memory.
    def initialize
      new
      super
    end

    # Finalizes object by freeing allocated memory.
    def finalize
      unref if ptr?
    end

    # Removes the callbacks and frees allocated memory.
    def close : Nil
      return unless ptr?

      # Unlike `#clear_callbacks`, the error messages are not tracked anymore
      # either, since the context is gone (which also keeps the callbacks
      # of an already closed context from being set on a null pointer)
      {% for key in %w[cancel idle status message error] %}
        unset_{{ key.id }}_callback
      {% end %}
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
