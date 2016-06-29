module GPhoto2
  module FFI
    @[Link("libgphoto2_port")]
    lib LibGPhoto2Port

      #
      # Structs
      #

      struct GPPortInfoList
        info : GPPortInfo*
        count : LibC::UInt
        iolib_count : LibC::UInt
      end

      #
      # Functions
      #

      fun gp_port_info_list_new(list : GPPortInfoList**) : LibC::Int
      fun gp_port_info_list_free(list : GPPortInfoList*) : LibC::Int
      fun gp_port_info_list_append(list : GPPortInfoList*, info : GPPortInfo*) : LibC::Int
      fun gp_port_info_list_load(list : GPPortInfoList*) : LibC::Int
      fun gp_port_info_list_count(list : GPPortInfoList*) : LibC::Int
      fun gp_port_info_list_lookup_path(list : GPPortInfoList*, path : LibC::Char*) : LibC::Int
      fun gp_port_info_list_lookup_name(list : GPPortInfoList*, name : LibC::Char*) : LibC::Int
      fun gp_port_info_list_get_info(list : GPPortInfoList*, n : LibC::Int, info : GPPortInfo*) : LibC::Int

    end
  end
end
