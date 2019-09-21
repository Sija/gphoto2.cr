require "./struct"

module GPhoto2
  module ManagedStruct(T)
    include Struct(T)

    getter ptr : T* { Pointer(T).malloc }

    def initialize(ptr : T*? = nil)
      self.ptr = ptr
    end

    protected def ptr=(ptr) : T*?
      # Debug.log ptr, backtrace_offset: 1
      if ptr
        self.ptr.copy_from(ptr, 1)
      else
        @ptr = ptr
      end
    end
  end
end
