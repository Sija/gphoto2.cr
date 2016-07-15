@[Link("libgphoto2")]
lib LibGPhoto2
  #
  # Structs
  #

  struct CameraListEntry
    name : LibC::Char*
    value : LibC::Char*
  end

  struct CameraList
    used : LibC::Int
    max : LibC::Int
    entry : CameraListEntry*
    ref_count : LibC::Int
  end

  #
  # Functions
  #

  fun gp_list_new(list : CameraList**) : LibC::Int
  fun gp_list_ref(list : CameraList*) : LibC::Int
  fun gp_list_unref(list : CameraList*) : LibC::Int
  fun gp_list_free(list : CameraList*) : LibC::Int
  fun gp_list_count(list : CameraList*) : LibC::Int
  fun gp_list_append(list : CameraList*, name : LibC::Char*, value : LibC::Char*) : LibC::Int
  fun gp_list_reset(list : CameraList*) : LibC::Int
  fun gp_list_sort(list : CameraList*) : LibC::Int
  fun gp_list_find_by_name(list : CameraList*, index : LibC::Int*, name : LibC::Char*) : LibC::Int
  fun gp_list_get_name(list : CameraList*, index : LibC::Int, name : LibC::Char**) : LibC::Int
  fun gp_list_get_value(list : CameraList*, index : LibC::Int, value : LibC::Char**) : LibC::Int
  fun gp_list_set_name(list : CameraList*, index : LibC::Int, name : LibC::Char*) : LibC::Int
  fun gp_list_set_value(list : CameraList*, index : LibC::Int, value : LibC::Char*) : LibC::Int
  fun gp_list_populate(list : CameraList*, format : LibC::Char*, count : LibC::Int) : LibC::Int
end
