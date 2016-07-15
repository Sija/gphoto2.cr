require "./camera_file"

@[Link("libgphoto2")]
lib LibGPhoto2
  struct GPContext; end

  struct CameraWidget; end

  struct CameraList; end

  #
  # Enums
  #

  enum CameraDriverStatus
    Production
    Testing
    Experimental
    Deprecated
  end

  enum GphotoDeviceType
    StillCamera
    AudioPlayer
  end

  @[Flags]
  enum CameraOperation
    CaptureImage
    CaptureVideo
    CaptureAudio
    CapturePreview
    Config
    TriggerCapture
  end

  @[Flags]
  enum CameraFolderOperation
    DeleteAll
    PutFile
    MakeDir
    RemoveDir
  end

  enum CameraCaptureType
    Image
    Movie
    Sound
  end

  enum CameraEventType
    Unknown
    Timeout
    FileAdded
    FolderAdded
    CaptureComplete
  end

  #
  # Aliases
  #

  alias CameraPrivateLibrary      = Void*
  alias CameraPrivateCore         = Void*

  alias CameraGetConfigFunc       = Camera*, CameraWidget**, GPContext* -> LibC::Int
  alias CameraSetConfigFunc       = Camera*, CameraWidget*, GPContext* -> LibC::Int

  alias CameraGetSingleConfigFunc = Camera*, LibC::Char*, CameraWidget**, GPContext* -> LibC::Int
  alias CameraSetSingleConfigFunc = Camera*, LibC::Char*, CameraWidget*, GPContext* -> LibC::Int

  alias CameraSummaryFunc         = Camera*, CameraText*, GPContext* -> LibC::Int
  alias CameraManualFunc          = Camera*, CameraText*, GPContext* -> LibC::Int
  alias CameraAboutFunc           = Camera*, CameraText*, GPContext* -> LibC::Int

  alias CameraTimeoutStartFunc    = Camera*, LibC::UInt, CameraTimeoutFunc, Void* -> LibC::Int
  alias CameraTimeoutStopFunc     = Camera*, LibC::UInt, Void* -> LibC::Int

  alias CameraPrePostFunc         = Camera*, GPContext* -> LibC::Int
  alias CameraTimeoutFunc         = Camera*, GPContext* -> LibC::Int
  alias CameraExitFunc            = Camera*, GPContext* -> LibC::Int

  alias CameraListConfigFunc      = Camera*, CameraList*, GPContext* -> LibC::Int
  alias CameraWaitForEvent        = Camera*, LibC::Int, CameraEventType*, Void**, GPContext* -> LibC::Int
  alias CameraCaptureFunc         = Camera*, CameraCaptureType, CameraFilePath*, GPContext* -> LibC::Int
  alias CameraTriggerCaptureFunc  = Camera*, GPContext* -> LibC::Int
  alias CameraCapturePreviewFunc  = Camera*, CameraFile*, GPContext* -> LibC::Int

  #
  # Structs
  #

  struct CameraAbilities
    model : LibC::Char[128]
    status : CameraDriverStatus
    port : LibC::Int
    speed : LibC::Int[64]
    operations : CameraOperation
    file_operations : CameraFileOperation
    folder_operations : CameraFolderOperation
    usb_vendor : LibC::Int
    usb_product : LibC::Int
    usb_class : LibC::Int
    usb_subclass : LibC::Int
    usb_protocol : LibC::Int
    library : LibC::Char[1024]
    id : LibC::Char[1024]
    device_type : GphotoDeviceType
    reserved2 : LibC::Int
    reserved3 : LibC::Int
    reserved4 : LibC::Int
    reserved5 : LibC::Int
    reserved6 : LibC::Int
    reserved7 : LibC::Int
    reserved8 : LibC::Int
  end

  struct CameraText
    text : LibC::Char[32768] # 32 * 1024
  end

  # FIXME!
  alias CameraFilesystem = Void*

  struct CameraFunctions
    pre_func : CameraPrePostFunc
    post_func : CameraPrePostFunc
    exit : CameraExitFunc
    get_config : CameraGetConfigFunc
    set_config : CameraSetConfigFunc
    list_config : CameraListConfigFunc
    get_single_config : CameraGetSingleConfigFunc
    set_single_config : CameraSetSingleConfigFunc
    capture : CameraCaptureFunc
    trigger_capture : CameraTriggerCaptureFunc
    capture_preview : CameraCapturePreviewFunc
    summary : CameraSummaryFunc
    manual : CameraManualFunc
    about : CameraAboutFunc
    wait_for_event : CameraWaitForEvent
    reserved1 : Void*
    reserved2 : Void*
    reserved3 : Void*
    reserved4 : Void*
    reserved5 : Void*
    reserved6 : Void*
    reserved7 : Void*
    reserved8 : Void*
  end

  struct Camera
    port : LibGPhoto2Port::GPPort*
    fs : CameraFilesystem*
    functions : CameraFunctions*
    pl : CameraPrivateLibrary*
    pc : CameraPrivateCore*
  end

  #
  # Functions
  #

  fun gp_camera_autodetect(list : CameraList*, context : GPContext*) : LibC::Int
  fun gp_camera_get_storageinfo(camera : Camera*, sifs : Void**, nrofsifs : Void*, context : GPContext*) : LibC::Int

  fun gp_camera_new(camera : Camera**) : LibC::Int
  fun gp_camera_init(camera : Camera*, context : GPContext*) : LibC::Int
  fun gp_camera_exit(camera : Camera*, context : GPContext*) : LibC::Int
  fun gp_camera_ref(camera : Camera*) : LibC::Int
  fun gp_camera_unref(camera : Camera*) : LibC::Int
  fun gp_camera_free(camera : Camera*) : LibC::Int

  fun gp_camera_get_summary(camera : Camera*, summary : CameraText*, context : GPContext*) : LibC::Int
  fun gp_camera_get_manual(camera : Camera*, manual : CameraText*, context : GPContext*) : LibC::Int
  fun gp_camera_get_about(camera : Camera*, about : CameraText*, context : GPContext*) : LibC::Int

  fun gp_camera_set_abilities(camera : Camera*, abilities : CameraAbilities) : LibC::Int
  fun gp_camera_get_abilities(camera : Camera*, abilities : CameraAbilities*) : LibC::Int

  fun gp_camera_set_port_info(camera : Camera*, info : LibGPhoto2Port::GPPortInfo*) : LibC::Int
  fun gp_camera_get_port_info(camera : Camera*, info : LibGPhoto2Port::GPPortInfo**) : LibC::Int

  fun gp_camera_set_port_speed(camera : Camera*, speed : LibC::Int) : LibC::Int
  fun gp_camera_get_port_speed(camera : Camera*) : LibC::Int

  fun gp_camera_capture(camera : Camera*, type : CameraCaptureType, path : CameraFilePath*, context : GPContext*) : LibC::Int
  fun gp_camera_capture_preview(camera : Camera*, file : CameraFile*, context : GPContext*) : LibC::Int
  fun gp_camera_trigger_capture(camera : Camera*, context : GPContext*) : LibC::Int
  fun gp_camera_wait_for_event(camera : Camera*, timeout : LibC::Int, eventtype : CameraEventType*, eventdata : Void**, context : GPContext*) : LibC::Int

  fun gp_camera_list_config(camera : Camera*, list : CameraList*, context : GPContext*) : LibC::Int
  fun gp_camera_set_config(camera : Camera*, window : CameraWidget*, context : GPContext*) : LibC::Int
  fun gp_camera_get_config(camera : Camera*, window : CameraWidget**, context : GPContext*) : LibC::Int
  fun gp_camera_set_single_config(camera : Camera*, name : LibC::Char*, widget : CameraWidget*, context : GPContext*) : LibC::Int
  fun gp_camera_get_single_config(camera : Camera*, name : LibC::Char*, widget : CameraWidget**, context : GPContext*) : LibC::Int

  fun gp_camera_folder_list_files(camera : Camera*, folder : LibC::Char*, list : CameraList*, context : GPContext*) : LibC::Int
  fun gp_camera_folder_list_folders(camera : Camera*, folder : LibC::Char*, list : CameraList*, context : GPContext*) : LibC::Int
  fun gp_camera_folder_delete_all(camera : Camera*, folder : LibC::Char*, context : GPContext*) : LibC::Int
  fun gp_camera_folder_put_file(camera : Camera*, folder : LibC::Char*, filename : LibC::Char*, type : CameraFileType, file : CameraFile*, context : GPContext*) : LibC::Int
  fun gp_camera_folder_make_dir(camera : Camera*, folder : LibC::Char*, name : LibC::Char*, context : GPContext*) : LibC::Int
  fun gp_camera_folder_remove_dir(camera : Camera*, folder : LibC::Char*, name : LibC::Char*, context : GPContext*) : LibC::Int

  fun gp_camera_file_get(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, type : CameraFileType, camera_file : CameraFile*, context : GPContext*) : LibC::Int
  fun gp_camera_file_read(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, type : CameraFileType, offset : LibC::UInt64T, buf : LibC::Char*, size : LibC::UInt64T*, context : GPContext*) : LibC::Int
  fun gp_camera_file_delete(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, context : GPContext*) : LibC::Int

  fun gp_camera_set_timeout_funcs(camera : Camera*, start_func : CameraTimeoutStartFunc, stop_func : CameraTimeoutStopFunc, data : Void*)
  fun gp_camera_start_timeout(camera : Camera*, timeout : LibC::UInt, func : CameraTimeoutFunc) : LibC::Int
  fun gp_camera_stop_timeout(camera : Camera*, id : LibC::UInt)
end
