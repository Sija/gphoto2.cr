require "./struct"

module GPhoto2
  class CameraList
    include GPhoto2::Struct(LibGPhoto2::CameraList)

    record Entry,
      name : String,
      value : String

    # NOTE: allocates memory.
    def initialize
      new
    end

    # Finalizes object by freeing allocated memory.
    def finalize
      free
    end

    # Returns number of entries in the list.
    def size : Int32
      count
    end

    # Returns an array of entries in the list.
    def to_a : Array(Entry)
      Array(Entry).new(size) do |i|
        Entry.new get_name(i), get_value(i)
      end
    end

    private def new
      GPhoto2.check! \
        LibGPhoto2.gp_list_new(out ptr)
      self.ptr = ptr
    end

    private def free
      GPhoto2.check! \
        LibGPhoto2.gp_list_free(self)
      self.ptr = nil
    end

    private def count
      GPhoto2.check! \
        LibGPhoto2.gp_list_count(self)
    end

    private def get_name(idx)
      GPhoto2.check! \
        LibGPhoto2.gp_list_get_name(self, idx, out ptr)
      ptr ? String.new(ptr) : ""
    end

    private def get_value(idx)
      GPhoto2.check! \
        LibGPhoto2.gp_list_get_value(self, idx, out ptr)
      ptr ? String.new(ptr) : ""
    end
  end
end
