require "./struct"

module GPhoto2
  class CameraList
    include GPhoto2::Struct(LibGPhoto2::CameraList)

    def initialize
      new
    end

    def finalize
      free
    end

    def size : Int32
      count
    end

    def to_a : Array(Entry)
      Array(Entry).new(size) { |i| Entry.new(self, i) }
    end

    private def new
      GPhoto2.check! LibGPhoto2.gp_list_new(out ptr)
      self.ptr = ptr
    end

    private def free
      GPhoto2.check! LibGPhoto2.gp_list_free(self)
      self.ptr = nil
    end

    private def count
      GPhoto2.check! LibGPhoto2.gp_list_count(self)
    end
  end
end
