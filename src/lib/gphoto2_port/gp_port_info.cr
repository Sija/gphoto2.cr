require "./gp_port_type"

@[Link("libgphoto2_port")]
lib LibGPhoto2Port

  #
  # Structs
  #

  struct GPPortInfo
    type : GPPortType
    name : LibC::Char*
    path : LibC::Char*
    library_filename : LibC::Char*
  end

  #
  # Functions
  #

  fun gp_port_info_new(info : GPPortInfo*) : LibC::Int
  fun gp_port_info_get_name(info : GPPortInfo*, name : LibC::Char**) : LibC::Int
  fun gp_port_info_set_name(info : GPPortInfo*, name : LibC::Char*) : LibC::Int
  fun gp_port_info_get_path(info : GPPortInfo*, path : LibC::Char**) : LibC::Int
  fun gp_port_info_set_path(info : GPPortInfo*, path : LibC::Char*) : LibC::Int
  fun gp_port_info_get_type(info : GPPortInfo*, type : GPPortType*) : LibC::Int
  fun gp_port_info_set_type(info : GPPortInfo*, type : GPPortType) : LibC::Int

  fun gp_port_info_get_library_filename(info : GPPortInfo*, lib : LibC::Char**) : LibC::Int
  fun gp_port_info_set_library_filename(info : GPPortInfo*, lib : LibC::Char*) : LibC::Int

end
