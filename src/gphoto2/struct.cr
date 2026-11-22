module GPhoto2
  module Struct(T)
    # Returns the wrapped pointer, or `nil` if not set
    # (i.e. after the object has been closed).
    getter? ptr : T*?

    # Returns the wrapped pointer, or a null pointer if not set.
    def ptr : T*
      @ptr || Pointer(T).null
    end

    # Wraps the given *ptr*, if any.
    def initialize(ptr : T*? = nil)
      self.ptr = ptr
    end

    # Returns the wrapped pointer, used when passed to C functions.
    def to_unsafe : T*
      # Debug.log ptr, backtrace_offset: 1
      ptr
    end

    # Returns wrapped value.
    #
    # Raises `GPhoto2::Exception` if there's no value to return,
    # i.e. after the object has been closed.
    def wrapped : T
      ptr = to_unsafe
      if ptr.null?
        raise GPhoto2::Exception.new("#{self.class} is closed or not initialized")
      end
      ptr.value
    end

    protected def ptr=(ptr) : T*?
      # Debug.log ptr, backtrace_offset: 1
      @ptr = ptr
    end
  end
end
