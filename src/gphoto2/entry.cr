module GPhoto2
  class Entry
    @camera_list : CameraList
    @index : Int32

    def initialize(@camera_list : CameraList, @index : Int32); end

    def name : String
      get_name.not_nil!
    end

    def value : String
      get_value.not_nil!
    end

    private def get_name
      GPhoto2.check! LibGPhoto2.gp_list_get_name(@camera_list, @index, out ptr)
      !ptr ? nil : String.new ptr
    end

    private def get_value
      GPhoto2.check! LibGPhoto2.gp_list_get_value(@camera_list, @index, out ptr)
      !ptr ? nil : String.new ptr
    end
  end
end
