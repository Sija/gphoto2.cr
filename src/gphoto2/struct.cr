module GPhoto2
  module Struct(T)
    @ptr : T*?
    getter :ptr

    def to_unsafe : T*?
      ptr
    end
  end
end