module GPhoto2
  # Represents file information.
  class CameraFileInfo
    # Returns information about the preview of the file.
    #
    # Raises `NilAssertionError` if not available, see `#preview?`.
    getter! preview : Preview

    # Returns information about the file itself.
    #
    # Raises `NilAssertionError` if not available, see `#file?`.
    getter! file : File

    # Returns information about the audio data of the file.
    #
    # Raises `NilAssertionError` if not available, see `#audio?`.
    getter! audio : Audio

    # Creates file information from the given libgphoto2 *info*,
    # with the parts having no fields set left out.
    def initialize(info : LibGPhoto2::CameraFileInfo)
      @preview = get_info info.preview, Preview
      @file = get_info info.file, File
      @audio = get_info info.audio, Audio
    end

    private def get_info(info, klass)
      klass.new pointerof(info) unless info.fields.none?
    end
  end
end

require "./camera_file_info/*"
