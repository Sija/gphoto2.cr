module GPhoto2
  module Struct(T)
    getter  ptr : T* { Pointer(T).null }
    getter? ptr : T*?

    def initialize(ptr : T*? = nil)
      self.ptr = ptr
    end

    def to_unsafe : T*
      # GPhoto2.log ptr, backtrace_offset: 1
      ptr
    end

    def wrapped : T
      ptr.value
    end

    protected def ptr=(ptr) : T*?
      # GPhoto2.log ptr, backtrace_offset: 1
      @ptr = ptr
    end
  end
end
