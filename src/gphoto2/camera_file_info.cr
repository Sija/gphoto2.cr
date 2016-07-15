require "./camera_file_info/*"

module GPhoto2
  class CameraFileInfo
    getter preview : CameraFileInfoPreview?
    getter file    : CameraFileInfoFile?
    getter audio   : CameraFileInfoAudio?

    def initialize(info : LibGPhoto2::CameraFileInfo)
      @preview = get_info info.preview, CameraFileInfoPreview
      @file    = get_info info.file,    CameraFileInfoFile
      @audio   = get_info info.audio,   CameraFileInfoAudio
    end

    protected def fields_any?(info)
      info.fields != LibGPhoto2::CameraFileInfoFields::None
    end

    private def get_info(info, klass)
      klass.new pointerof(info) if fields_any?(info)
    end
  end
end
