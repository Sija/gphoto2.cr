require "./base"

module GPhoto2
  class CameraFileInfo
    class Audio < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoAudio)
    end
  end
end
