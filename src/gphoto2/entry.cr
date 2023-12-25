module GPhoto2
  class Entry
    def initialize(@camera_list : CameraList, @index : Int32)
    end

    # Returns the name of the entry.
    def name : String
      get_name.not_nil!
    end

    # Returns the value of the entry.
    def value : String
      get_value.not_nil!
    end

    private def get_name
      GPhoto2.check! \
        LibGPhoto2.gp_list_get_name(@camera_list, @index, out ptr)
      String.new ptr if ptr
    end

    private def get_value
      GPhoto2.check! \
        LibGPhoto2.gp_list_get_value(@camera_list, @index, out ptr)
      String.new ptr if ptr
    end
  end
end
