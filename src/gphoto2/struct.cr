module GPhoto2
  module Struct(T)
    getter ptr : T* { Pointer(T).null }
    getter? ptr : T*?

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
