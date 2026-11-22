require "./camera_file_info"
require "./camera_file"

@[Link("libgphoto2")]
lib LibGPhoto2
  #
  # Enums
  #

  @[Flags]
  enum CameraStorageInfoFields
    Base
    Label
    Description
    Access
    StorageType
    FilesystemType
    MaxCapacity
    FreeSpaceKbytes
    FreeSpaceImages
  end

  enum CameraStorageType
    Unknown
    FixedRom
    RemovableRom
    FixedRam
    RemovableRam
  end

  enum CameraStorageAccessType
    ReadWrite
    ReadOnly
    ReadOnlyWithDelete
  end

  enum CameraStorageFilesystemType
    Undefined
    GenericFlat
    GenericHierarchical
    Dcf
  end

  #
  # Structs
  #

  struct CameraStorageInformation
    fields : CameraStorageInfoFields
    basedir : LibC::Char[256]
    label : LibC::Char[256]
    description : LibC::Char[256]
    type : CameraStorageType
    fstype : CameraStorageFilesystemType
    access : CameraStorageAccessType
    capacitykbytes : LibC::UInt64T
    freekbytes : LibC::UInt64T
    freeimages : LibC::UInt64T
  end

  #
  # Aliases
  #

  # NOTE: Opaque struct, its layout is private to libgphoto2.
  type CameraFilesystem = Void

  alias CameraFilesystemListFunc        = CameraFilesystem*, LibC::Char*, CameraList*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemSetInfoFunc     = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileInfo, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemGetInfoFunc     = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileInfo*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemGetFileFunc     = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileType, CameraFile*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemReadFileFunc    = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileType, LibC::UInt64T, LibC::Char*, LibC::UInt64T*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemDeleteFileFunc  = CameraFilesystem*, LibC::Char*, LibC::Char*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemPutFileFunc     = CameraFilesystem*, LibC::Char*, LibC::Char*, CameraFileType, CameraFile*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemDeleteAllFunc   = CameraFilesystem*, LibC::Char*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemDirFunc         = CameraFilesystem*, LibC::Char*, LibC::Char*, Void*, GPContext* -> LibC::Int
  alias CameraFilesystemStorageInfoFunc = CameraFilesystem*, CameraStorageInformation**, LibC::Int*, Void*, GPContext* -> LibC::Int

  #
  # Structs
  #

  struct CameraFilesystemFuncs
    file_list_func : CameraFilesystemListFunc
    folder_list_func : CameraFilesystemListFunc
    put_file_func : CameraFilesystemPutFileFunc
    delete_all_func : CameraFilesystemDeleteAllFunc
    get_info_func : CameraFilesystemGetInfoFunc
    set_info_func : CameraFilesystemSetInfoFunc
    make_dir_func : CameraFilesystemDirFunc
    remove_dir_func : CameraFilesystemDirFunc
    get_file_func : CameraFilesystemGetFileFunc
    read_file_func : CameraFilesystemReadFileFunc
    del_file_func : CameraFilesystemDeleteFileFunc
    storage_info_func : CameraFilesystemStorageInfoFunc
    unused : Void*[31]
  end

  #
  # Functions
  #

  fun gp_filesystem_new(fs : CameraFilesystem**) : LibC::Int
  fun gp_filesystem_free(fs : CameraFilesystem*) : LibC::Int
  fun gp_filesystem_reset(fs : CameraFilesystem*) : LibC::Int
  fun gp_filesystem_set_funcs(fs : CameraFilesystem*, funcs : CameraFilesystemFuncs*, data : Void*) : LibC::Int
end
