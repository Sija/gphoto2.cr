require "./struct"

module GPhoto2
  class CameraFileInfoAudio < CameraFileInfo
    include GPhoto2::Struct(LibGPhoto2::CameraFileInfoAudio)
  end
end