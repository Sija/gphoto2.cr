require "./struct"

module GPhoto2
  class CameraList
    record Entry,
      name : String,
      value : String

    include GPhoto2::Struct(LibGPhoto2::CameraList)
    include Enumerable(Entry)

    # NOTE: allocates memory.
    def initialize
      new
    end

    # Finalizes object by freeing allocated memory.
    def finalize
      close
    end

    # Frees allocated memory.
    def close : Nil
      free if ptr?
    end

    # Returns number of entries in the list.
    def size : Int32
      count
    end

    # Returns `true` if the list has no entries.
    #
    # NOTE: Overrides `Enumerable#empty?`, so that it doesn't need to fetch
    # the first entry (see `#each`), which takes two more calls into libgphoto2.
    def empty? : Bool
      size.zero?
    end

    # Yields each entry in the list.
    #
    # ```
    # list.each do |entry|
    #   puts "#{entry.name}: #{entry.value}"
    # end
    # ```
    def each(& : Entry ->) : Nil
      size.times do |i|
        yield Entry.new(get_name(i), get_value(i))
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
