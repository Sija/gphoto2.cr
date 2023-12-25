require "./base"

module GPhoto2
  class CameraFileInfo
    # Represents audio information.
    class Audio < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoAudio)
    end
  end
end
