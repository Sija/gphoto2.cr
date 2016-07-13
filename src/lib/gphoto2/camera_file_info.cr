@[Link("libgphoto2")]
lib LibGPhoto2

  #
  # Enums
  #

  @[Flags]
  enum CameraFileInfoFields
    Type
    Size
    Width
    Height
    Permissions
    Status
    Mtime
  end

  @[Flags]
  enum CameraFilePermissions
    Read
    Delete
  end

  enum CameraFileStatus
    NotDownloaded
    Downloaded
  end

  #
  # Structs
  #

  struct CameraFileInfoPreview
    fields : CameraFileInfoFields
    status : CameraFileStatus
    size : UInt64
    type : LibC::Char[64]
    width : UInt32 
    height : UInt32
  end

  struct CameraFileInfoFile
    fields : CameraFileInfoFields
    status : CameraFileStatus
    size : UInt64
    type : LibC::Char[64]
    width : UInt32 
    height : UInt32
    permissions : CameraFilePermissions
    mtime : LibC::TimeT
  end

  struct CameraFileInfoAudio
    fields : CameraFileInfoFields
    status : CameraFileStatus
    size : UInt64
    type : LibC::Char[64]
  end

  struct CameraFileInfo
    preview : CameraFileInfoPreview
    file : CameraFileInfoFile
    audio : CameraFileInfoAudio
  end

  #
  # Functions
  #

  fun gp_camera_file_get_info(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, info : CameraFileInfo*, context : GPContext*) : LibC::Int
  fun gp_camera_file_set_info(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, info : CameraFileInfo, context : GPContext*) : LibC::Int

end
