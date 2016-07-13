require "./struct"

module GPhoto2
  module ManagedStruct(T)
    include Struct(T)

    def ptr : T*
      @ptr ||= Pointer(T).malloc
    end
  end
end
