require "./struct"

module GPhoto2
  module ManagedStruct(T)
    include Struct(T)

    def initialize(ptr : T*? = nil)
      self.ptr = ptr
    end

    def ptr : T*
      @ptr ||= Pointer(T).malloc
    end

    protected def ptr=(ptr) : T*?
      # GPhoto2.log ptr, backtrace_offset: 2
      if ptr
        self.ptr.copy_from(ptr, 1)
      else
        @ptr = ptr
      end
    end
  end
end
