require "./gphoto2_port"
require "./gphoto2/*"

@[Link("libgphoto2")]
lib LibGPhoto2

  #
  # Constants
  #

  GP_OK = 0
  GP_ERROR = -1
  GP_ERROR_BAD_PARAMETERS = -2
  GP_ERROR_NO_MEMORY = -3
  GP_ERROR_LIBRARY = -4
  GP_ERROR_UNKNOWN_PORT = -5
  GP_ERROR_NOT_SUPPORTED = -6
  GP_ERROR_IO = -7
  GP_ERROR_FIXED_LIMIT_EXCEEDED = -8
  GP_ERROR_TIMEOUT = -10
  GP_ERROR_IO_SUPPORTED_SERIAL = -20
  GP_ERROR_IO_SUPPORTED_USB = -21
  GP_ERROR_IO_INIT = -31
  GP_ERROR_IO_READ = -34
  GP_ERROR_IO_WRITE = -35
  GP_ERROR_IO_UPDATE = -37
  GP_ERROR_IO_SERIAL_SPEED = -41
  GP_ERROR_IO_USB_CLEAR_HALT = -51
  GP_ERROR_IO_USB_FIND = -52
  GP_ERROR_IO_USB_CLAIM = -53
  GP_ERROR_IO_LOCK = -60
  GP_ERROR_HAL = -70

  GP_ERROR_CORRUPTED_DATA = -102
  GP_ERROR_FILE_EXISTS = -103
  GP_ERROR_MODEL_NOT_FOUND = -105
  GP_ERROR_DIRECTORY_NOT_FOUND = -107
  GP_ERROR_FILE_NOT_FOUND = -108
  GP_ERROR_DIRECTORY_EXISTS = -109
  GP_ERROR_CAMERA_BUSY = -110
  GP_ERROR_PATH_NOT_ABSOLUTE = -111
  GP_ERROR_CANCEL = -112
  GP_ERROR_CAMERA_ERROR = -113
  GP_ERROR_OS_FAILURE = -114
  GP_ERROR_NO_SPACE = -115

  GP_MIME_TXT = "text/plain"
  GP_MIME_WAV = "audio/wav"
  GP_MIME_RAW = "image/x-raw"
  GP_MIME_PNG = "image/png"
  GP_MIME_PGM = "image/x-portable-graymap"
  GP_MIME_PPM = "image/x-portable-pixmap"
  GP_MIME_PNM = "image/x-portable-anymap"
  GP_MIME_JPEG = "image/jpeg"
  GP_MIME_TIFF = "image/tiff"
  GP_MIME_BMP = "image/bmp"
  GP_MIME_QUICKTIME = "video/quicktime"
  GP_MIME_AVI = "video/x-msvideo"
  GP_MIME_CRW = "image/x-canon-raw"
  GP_MIME_CR2 = "image/x-canon-cr2"
  GP_MIME_NEF = "image/x-nikon-nef"
  GP_MIME_UNKNOWN = "application/octet-stream"
  GP_MIME_EXIF = "application/x-exif"
  GP_MIME_MP3 = "audio/mpeg"
  GP_MIME_OGG = "application/ogg"
  GP_MIME_WMA = "audio/x-wma"
  GP_MIME_ASF = "audio/x-asf"
  GP_MIME_MPEG = "video/mpeg"
  GP_MIME_AVCHD = "video/mp2t"
  GP_MIME_RW2 = "image/x-panasonic-raw2"
  GP_MIME_ARW = "image/x-sony-arw"

  #
  # Enums
  #

  enum GPVersionVerbosity
    Short
    Verbose
  end

  #
  # Functions
  #

  fun gp_setting_set(id : LibC::Char*, key : LibC::Char*, value : LibC::Char*) : LibC::Int
  fun gp_setting_get(id : LibC::Char*, key : LibC::Char*, value : LibC::Char*) : LibC::Int

  fun gp_result_as_string(result : LibC::Int) : LibC::Char*
  fun gp_message_codeset(codeset : LibC::Char*) : LibC::Char*
  fun gp_library_version(verbose : GPVersionVerbosity) : LibC::Char**

end
