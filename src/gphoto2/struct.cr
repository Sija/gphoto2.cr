module GPhoto2
  module Struct(T)
    @ptr : T*?

    def initialize(ptr : T*? = nil)
      self.ptr = ptr
    end

    def to_unsafe : T*
      # GPhoto2.log ptr, backtrace_offset: 2
      ptr
    end

    def wrapped : T
      ptr.value
    end

    def ptr? : T*?
      @ptr
    end

    def ptr : T*
      @ptr ||= Pointer(T).null
    end

    protected def ptr=(ptr) : T*?
      # GPhoto2.log ptr, backtrace_offset: 2
      @ptr = ptr
    end
  end
end
