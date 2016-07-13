@[Link("libgphoto2")]
lib LibGPhoto2

  #
  # Enums
  #

  @[Flags]
  enum CameraFileOperation
    Delete  = (1 << 1)
    Preview = (1 << 3)
    RAW
    Audio
    EXIF
  end

  enum CameraFileType
    Preview
    Normal
    RAW
    Audio
    EXIF
    Metadata
  end

  enum CameraFileAccessType
    Memory
    FD
    Handler
  end

  #
  # Structs
  #

  struct CameraFile
    mime_type : LibC::Char[64]
    name : LibC::Char[256]
    ref_count : LibC::Int
    mtime : LibC::TimeT
    accesstype : CameraFileAccessType
    size : LibC::ULong
    data : LibC::Char*
    offset : LibC::ULong
    fd : LibC::Int
    handler : CameraFileHandler*
    private : Void*
  end

  struct CameraFileHandler
    size : (Void*, LibC::UInt64T* -> LibC::Int)
    read : (Void*, LibC::UChar*, LibC::UInt64T* -> LibC::Int)
    write : (Void*, LibC::UChar*, LibC::UInt64T* -> LibC::Int)
  end

  struct CameraFilePath
    name : LibC::Char[128]
    folder : LibC::Char[1024]
  end

  #
  # Functions
  #

  fun gp_file_new(file : CameraFile**) : LibC::Int
  fun gp_file_new_from_fd(file : CameraFile**, fd : LibC::Int) : LibC::Int
  fun gp_file_new_from_handler(file : CameraFile**, handler : CameraFileHandler*, priv : Void*) : LibC::Int
  fun gp_file_ref(file : CameraFile*) : LibC::Int
  fun gp_file_unref(file : CameraFile*) : LibC::Int
  fun gp_file_free(file : CameraFile*) : LibC::Int

  fun gp_file_set_name(file : CameraFile*, name : LibC::Char*) : LibC::Int
  fun gp_file_get_name(file : CameraFile*, name : LibC::Char**) : LibC::Int

  fun gp_file_detect_mime_type(file : CameraFile*) : LibC::Int
  fun gp_file_adjust_name_for_mime_type(file : CameraFile*) : LibC::Int

  fun gp_file_set_mime_type(file : CameraFile*, mime_type : LibC::Char*) : LibC::Int
  fun gp_file_get_mime_type(file : CameraFile*, mime_type : LibC::Char**) : LibC::Int

  fun gp_file_set_mtime(file : CameraFile*, mtime : LibC::TimeT) : LibC::Int
  fun gp_file_get_mtime(file : CameraFile*, mtime : LibC::TimeT*) : LibC::Int

  fun gp_file_set_data_and_size(camerafile : CameraFile*, data : LibC::Char*, size : LibC::ULong) : LibC::Int
  fun gp_file_get_data_and_size(camerafile : CameraFile*, data : LibC::Char**, size : LibC::ULong*) : LibC::Int

  fun gp_file_get_name_by_type(file : CameraFile*, basename : LibC::Char*, type : CameraFileType, newname : LibC::Char**) : LibC::Int
  fun gp_file_open(file : CameraFile*, filename : LibC::Char*) : LibC::Int
  fun gp_file_save(file : CameraFile*, filename : LibC::Char*) : LibC::Int
  fun gp_file_clean(file : CameraFile*) : LibC::Int
  fun gp_file_copy(destination : CameraFile*, source : CameraFile*) : LibC::Int
  fun gp_file_append(camerafile : CameraFile*, data : LibC::Char*, size : LibC::ULong) : LibC::Int
  fun gp_file_slurp(camerafile : CameraFile*, data : LibC::Char*, size : LibC::SizeT, readlen : LibC::SizeT*) : LibC::Int

end
