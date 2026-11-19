module GPhoto2
  module Struct(T)
    getter? ptr : T*?

    # Returns the wrapped pointer, or a null pointer if not set.
    def ptr : T*
      @ptr || Pointer(T).null
    end

    def initialize(ptr : T*? = nil)
      self.ptr = ptr
    end

    def to_unsafe : T*
      # Debug.log ptr, backtrace_offset: 1
      ptr
    end

    # Returns wrapped value.
    def wrapped : T
      ptr.value
    end

    protected def ptr=(ptr) : T*?
      # Debug.log ptr, backtrace_offset: 1
      @ptr = ptr
    end
  end
end
