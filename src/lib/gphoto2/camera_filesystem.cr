require "./camera_file_info"
require "./camera_file"

@[Link("libgphoto2")]
lib LibGPhoto2
  #
  # Aliases
  #

  # TODO?
  alias CameraStorageInformation = Void

  alias CameraFilesystemListFunc        = CameraFilesystem*, LibC::Char*, CameraList*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemSetInfoFunc     = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileInfo, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemGetInfoFunc     = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileInfo, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemGetFileFunc     = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileType, CameraFile*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemReadFileFunc    = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileType, LibC::UInt64T, LibC::Char*, LibC::UInt64T, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemDeleteFileFunc  = CameraFilesystem*, LibC::Char*, LibC::Char*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemPutFileFunc     = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileType, CameraFile*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemDeleteAllFunc   = CameraFilesystem*, LibC::Char*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemDirFunc         = CameraFilesystem*, LibC::Char*, LibC::Char*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemStorageInfoFunc = CameraFilesystem*, CameraStorageInformation**, LibC::Int, Void*, GPContext* -> LibC::Int

  #
  # Structs
  #

  struct CameraFilesystemFile
    name : LibC::Char*
    info_dirty : LibC::Int
    info : CameraFileInfo
    lru_prev : CameraFilesystemFile*
    lru_next : CameraFilesystemFile*
    preview : CameraFile*
    normal : CameraFile*
    raw : CameraFile*
    audio : CameraFile*
    exif : CameraFile*
    metadata : CameraFile*
    next : CameraFilesystemFile*
  end

  struct CameraFilesystemFolder
    name : LibC::Char*
    files_dirty : LibC::Int
    folders_dirty : LibC::Int
    next : CameraFilesystemFolder*
    folders : CameraFilesystemFolder*
    files : CameraFilesystemFile*
  end

  struct CameraFilesystem
    rootfolder : CameraFilesystemFolder*
    lru_first : CameraFilesystemFile*
    lru_last : CameraFilesystemFile*
    lru_size : LibC::UInt
    get_info_func : CameraFilesystemGetInfoFunc
    set_info_func : CameraFilesystemSetInfoFunc
    file_list_func : CameraFilesystemListFunc
    folder_list_func : CameraFilesystemListFunc
    get_file_func : CameraFilesystemGetFileFunc
    read_file_func : CameraFilesystemReadFileFunc
    delete_file_func : CameraFilesystemDeleteFileFunc
    put_file_func : CameraFilesystemPutFileFunc
    delete_all_func : CameraFilesystemDeleteAllFunc
    make_dir_func : CameraFilesystemDirFunc
    remove_dir_func : CameraFilesystemDirFunc
    storage_info_func : CameraFilesystemStorageInfoFunc
    data : Void*
  end

  #
  # Functions
  #

  fun gp_filesystem_new(fs : CameraFilesystem*) : LibC::Int
  fun gp_filesystem_free(fs : CameraFilesystem*) : LibC::Int
  fun gp_filesystem_reset(fs : CameraFilesystem*) : LibC::Int
end
