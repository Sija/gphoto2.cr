require "./struct"

module GPhoto2
  class Entry; end

  class CameraList
    include GPhoto2::Struct(LibGPhoto2::CameraList)

    def initialize
      new
    end

    def size : Int32
      count
    end

    def length
      size
    end

    def to_a : Array(Entry)
      size.times.map { |i| Entry.new(self, i) }.to_a
    end

    private def new
      GPhoto2.check! LibGPhoto2.gp_list_new(out ptr)
      self.ptr = ptr
    end

    private def count
      GPhoto2.check! LibGPhoto2.gp_list_count(self)
    end
  end
end