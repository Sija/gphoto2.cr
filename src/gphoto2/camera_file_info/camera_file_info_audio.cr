require "./camera_file_info_base"

module GPhoto2
  class CameraFileInfoAudio < CameraFileInfo::Base
    include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoAudio)
  end
end
