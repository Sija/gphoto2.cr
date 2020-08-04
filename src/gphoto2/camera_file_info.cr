module GPhoto2
  class CameraFileInfo
    getter! preview : Preview
    getter! file    : File
    getter! audio   : Audio

    def initialize(info : LibGPhoto2::CameraFileInfo)
      @preview = get_info info.preview, Preview
      @file    = get_info info.file,    File
      @audio   = get_info info.audio,   Audio
    end

    private def fields_any?(info)
      info.fields != CameraFileInfoFields::None
    end

    private def get_info(info, klass)
      klass.new pointerof(info) if fields_any?(info)
    end
  end
end

require "./camera_file_info/*"
