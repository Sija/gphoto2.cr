@[Link("libgphoto2")]
lib LibGPhoto2
  #
  # Structs
  #

  struct CameraAbilitiesList
    count : LibC::Int
    abilities : CameraAbilities*
  end

  #
  # Functions
  #

  fun gp_abilities_list_new(list : CameraAbilitiesList**) : LibC::Int
  fun gp_abilities_list_free(list : CameraAbilitiesList*) : LibC::Int
  fun gp_abilities_list_load(list : CameraAbilitiesList*, context : GPContext*) : LibC::Int
  fun gp_abilities_list_load_dir(list : CameraAbilitiesList*, dir : LibC::Char*, context : GPContext*) : LibC::Int
  fun gp_abilities_list_reset(list : CameraAbilitiesList*) : LibC::Int
  fun gp_abilities_list_detect(list : CameraAbilitiesList*, info_list : LibGPhoto2Port::GPPortInfoList*, l : CameraList*, context : GPContext*) : LibC::Int
  fun gp_abilities_list_append(list : CameraAbilitiesList*, abilities : CameraAbilities) : LibC::Int
  fun gp_abilities_list_count(list : CameraAbilitiesList*) : LibC::Int
  fun gp_abilities_list_lookup_model(list : CameraAbilitiesList*, model : LibC::Char*) : LibC::Int
  fun gp_abilities_list_get_abilities(list : CameraAbilitiesList*, index : LibC::Int, abilities : CameraAbilities*) : LibC::Int
end
