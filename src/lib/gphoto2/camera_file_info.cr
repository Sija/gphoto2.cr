@[Link("libgphoto2")]
lib LibGPhoto2

  #
  # Enums
  #

  @[Flags]
  enum CameraFileInfoFields
    Type    = (1 << 0)
    Size    = (1 << 2)
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
    size : LibC::UInt64T
    type : LibC::Char[64]
    width : LibC::UInt32T
    height : LibC::UInt32T
  end

  struct CameraFileInfoFile
    fields : CameraFileInfoFields
    status : CameraFileStatus
    size : LibC::UInt64T
    type : LibC::Char[64]
    width : LibC::UInt32T
    height : LibC::UInt32T
    permissions : CameraFilePermissions
    mtime : LibC::TimeT
  end

  struct CameraFileInfoAudio
    fields : CameraFileInfoFields
    status : CameraFileStatus
    size : LibC::UInt64T
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
