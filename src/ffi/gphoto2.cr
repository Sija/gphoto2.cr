# @[Link(ldflags: "`pkg-config libgphoto2 --libs`")]
# @[Link(ldflags: "`pkg-config libgphoto2_port --libs`")]
@[Link("libgphoto2")]
lib LibGPhoto2
  #
  # Constants
  #

  GP_PORT_MAX_BUF_LEN = 4096

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

  @[Flags]
  enum GPPortType
    Serial
    USB = (1 << 2)
    Disk
    PTPIP
    USBDiskDirect
    USBSCSI
  end

  enum GPPortSerialParity
    Off
    Even
    Odd
  end

  enum GPPin
    RTS
    DTR
    CTS
    DSR
    CD
    RING
  end

  enum GPLevel
    LOW
    HIGH
  end

  enum GPLogLevel
    Error
    Verbose
    Debug
  end

  enum GPContextFeedback
    OK
    Cancel
  end

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
  enum CameraFileOperation
    Delete  = (1 << 1)
    Preview = (1 << 3)
    RAW
    Audio
    EXIF
  end

  @[Flags]
  enum CameraFolderOperation
    DeleteAll
    PutFile
    MakeDir
    RemoveDir
  end

  enum CameraWidgetType
    Window
    Section
    Text
    Range
    Toggle
    Radio
    Menu
    Button
    Date
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

  enum GPVersionVerbosity
    Short
    Verbose
  end

  #
  # Aliases
  #

  alias GPPortPrivateLibrary = Void*
  alias GPPortPrivateCore = Void*
  alias CameraPrivateLibrary = Void*
  alias CameraPrivateCore = Void*

  alias GPLogFunc = (GPLogLevel, LibC::Char*, LibC::Char*, Void* ->)

  alias GPContextIdleFunc = (GPContext*, Void* ->)
  alias GPContextErrorFunc = (GPContext*, LibC::Char*, Void*, Void* ->)
  alias GPContextStatusFunc = (GPContext*, LibC::Char*, Void*, Void* ->)
  alias GPContextMessageFunc = (GPContext*, LibC::Char*, Void*, Void* ->)
  alias GPContextQuestionFunc = (GPContext*, LibC::Char*, Void*, Void* -> GPContextFeedback)
  alias GPContextCancelFunc = (GPContext*, Void* -> GPContextFeedback)
  alias GPContextProgressStartFunc = (GPContext*, LibC::Float, LibC::Char*, Void*, Void* -> LibC::UInt)
  alias GPContextProgressUpdateFunc = (GPContext*, LibC::Int, LibC::Float, Void* ->)
  alias GPContextProgressStopFunc = (GPContext*, LibC::Int, Void* ->)

  alias CameraWidgetCallback = (Camera*, CameraWidget*, GPContext* -> LibC::Int)
  alias CameraPrePostFunc = (Camera*, GPContext* -> LibC::Int)
  alias CameraExitFunc = (Camera*, GPContext* -> LibC::Int)
  alias CameraGetConfigFunc = (Camera*, CameraWidget**, GPContext* -> LibC::Int)
  alias CameraGetSingleConfigFunc = (Camera*, LibC::Char*, CameraWidget**, GPContext* -> LibC::Int)
  alias CameraListConfigFunc = (Camera*, CameraList*, GPContext* -> LibC::Int)
  alias CameraSetConfigFunc = (Camera*, CameraWidget*, GPContext* -> LibC::Int)
  alias CameraSetSingleConfigFunc = (Camera*, LibC::Char*, CameraWidget*, GPContext* -> LibC::Int)
  alias CameraCaptureFunc = (Camera*, CameraCaptureType, CameraFilePath*, GPContext* -> LibC::Int)
  alias CameraTriggerCaptureFunc = (Camera*, GPContext* -> LibC::Int)
  alias CameraCapturePreviewFunc = (Camera*, CameraFile*, GPContext* -> LibC::Int)
  alias CameraSummaryFunc = (Camera*, CameraText*, GPContext* -> LibC::Int)
  alias CameraManualFunc = (Camera*, CameraText*, GPContext* -> LibC::Int)
  alias CameraAboutFunc = (Camera*, CameraText*, GPContext* -> LibC::Int)
  alias CameraWaitForEvent = (Camera*, LibC::Int, CameraEventType*, Void**, GPContext* -> LibC::Int)
  alias CameraTimeoutFunc = (Camera*, GPContext* -> LibC::Int)
  alias CameraTimeoutStartFunc = (Camera*, LibC::UInt, CameraTimeoutFunc, Void* -> LibC::Int)
  alias CameraTimeoutStopFunc = (Camera*, LibC::UInt, Void* -> LibC::Int)

  #
  # Structs
  #

  struct GPPortInfo
    type : GPPortType
    name : LibC::Char*
    path : LibC::Char*
    library_filename : LibC::Char*
  end

  struct GPPortInfoList
    info : GPPortInfo*
    count : LibC::UInt
    iolib_count : LibC::UInt
  end

  struct GPPortSettingsSerial
    port : LibC::Char[128]
    speed : LibC::Int
    bits : LibC::Int
    parity : GPPortSerialParity
    stopbits : LibC::Int
  end

  struct GPPortSettingsUSB
    inep : LibC::Int
    outep : LibC::Int
    intep : LibC::Int
    config : LibC::Int
    interface : LibC::Int
    altsetting : LibC::Int
    maxpacketsize : LibC::Int
    port : LibC::Char[64]
  end

  struct GPPortSettingsUsbDiskDirect
    path : LibC::Char[128]
  end

  struct GPPortSettingsUsbScsi
    path : LibC::Char[128]
  end

  union GPPortSettings
    serial : GPPortSettingsSerial
    usb : GPPortSettingsUSB
    usbdiskdirect : GPPortSettingsUsbDiskDirect
    usbscsi : GPPortSettingsUsbScsi
  end

  struct GPPort
    type : GPPortType
    settings : GPPortSettings
    settings_pending : GPPortSettings
    timeout : LibC::Int
    pl : GPPortPrivateLibrary*
    pc : GPPortPrivateCore*
  end

  struct GPContext
    idle_func : GPContextIdleFunc
    idle_func_data : Void*

    progress_start_func : GPContextProgressStartFunc
    progress_update_func : GPContextProgressUpdateFunc
    progress_stop_func : GPContextProgressStopFunc
    progress_func_data : Void*

    error_func : GPContextErrorFunc
    error_func_data : Void*

    question_func : GPContextQuestionFunc
    question_func_data : Void*

    cancel_func : GPContextCancelFunc
    cancel_func_data : Void*

    status_func : GPContextStatusFunc
    status_func_data : Void*

    message_func : GPContextMessageFunc
    message_func_data : Void*

    ref_count : LibC::UInt
  end

  struct CameraListEntry
    name : LibC::Char*
    value : LibC::Char*
  end

  struct CameraList
    used : LibC::Int
    max : LibC::Int
    entry : CameraListEntry*
    ref_count : LibC::Int
  end

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

  struct CameraAbilitiesList
    count : LibC::Int
    abilities : CameraAbilities*
  end

  struct CameraWidget
    type : CameraWidgetType
    label : LibC::Char[256]
    info : LibC::Char[1024]
    name : LibC::Char[256]
    parent : CameraWidget*
    value_string : LibC::Char*
    value_int : LibC::Int
    value_float : LibC::Float
    choice : LibC::Char**
    choice_count : LibC::Int
    min : LibC::Float
    max : LibC::Float
    increment : LibC::Float
    children : CameraWidget**
    children_count : LibC::Int
    changed : LibC::Int
    readonly : LibC::Int
    ref_count : LibC::Int
    id : LibC::Int
    callback : CameraWidgetCallback
  end

  struct CameraFileHandler
    size : (Void*, LibC::UInt64T* -> LibC::Int)
    read : (Void*, LibC::UChar*, LibC::UInt64T* -> LibC::Int)
    write : (Void*, LibC::UChar*, LibC::UInt64T* -> LibC::Int)
  end

  struct CameraText
    text : LibC::Char[32768] # 32 * 1024
  end

  struct CameraFilePath
    name : LibC::Char[128]
    folder : LibC::Char[1024]
  end

  # FIXME!
  struct CameraFileInfo
    preview : Void*
    file : Void*
    audio : Void*
  end

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
    port : GPPort*
    fs : Void*
    functions : CameraFunctions*
    pl : CameraPrivateLibrary*
    pc : CameraPrivateCore*
  end

  # gp_log_*
  fun gp_log_add_func(level : GPLogLevel, func : GPLogFunc, data : Void*) : LibC::Int
  fun gp_log_remove_func(id : LibC::Int) : LibC::Int

  fun gp_log(level : GPLogLevel, domain : LibC::Char*, format : LibC::Char*, ...)
  fun gp_logv(level : GPLogLevel, domain : LibC::Char*, format : LibC::Char*, args : Void*)

  fun gp_log_with_source_location(level : GPLogLevel, file : LibC::Char*, line : LibC::Int, func : LibC::Char*, format : LibC::Char*, ...)
  fun gp_log_data(domain : LibC::Char*, data : LibC::Char*, size : LibC::UInt, format : LibC::Char*, ...)

  # gp_setting_*
  fun gp_setting_set(id : LibC::Char*, key : LibC::Char*, value : LibC::Char*) : LibC::Int
  fun gp_setting_get(id : LibC::Char*, key : LibC::Char*, value : LibC::Char*) : LibC::Int

  # gp_port_*
  fun gp_port_new(port : GPPort**) : LibC::Int
  fun gp_port_free(port : GPPort*) : LibC::Int

  fun gp_port_set_info(port : GPPort*, info : GPPortInfo) : LibC::Int
  fun gp_port_get_info(port : GPPort*, info : GPPortInfo*) : LibC::Int

  fun gp_port_open(port : GPPort*) : LibC::Int
  fun gp_port_close(port : GPPort*) : LibC::Int
  fun gp_port_reset(port : GPPort*) : LibC::Int

  fun gp_port_write(port : GPPort*, data : LibC::Char*, size : LibC::Int) : LibC::Int
  fun gp_port_read(port : GPPort*, data : LibC::Char*, size : LibC::Int) : LibC::Int

  fun gp_port_check_int(port : GPPort*, data : LibC::Char*, size : LibC::Int) : LibC::Int
  fun gp_port_check_int_fast(port : GPPort*, data : LibC::Char*, size : LibC::Int) : LibC::Int

  fun gp_port_get_timeout(port : GPPort*, timeout : LibC::Int*) : LibC::Int
  fun gp_port_set_timeout(port : GPPort*, timeout : LibC::Int) : LibC::Int

  fun gp_port_set_settings(port : GPPort*, settings : GPPortSettings) : LibC::Int
  fun gp_port_get_settings(port : GPPort*, settings : GPPortSettings*) : LibC::Int

  fun gp_port_get_pin(port : GPPort*, pin : GPPin, level : GPLevel*) : LibC::Int
  fun gp_port_set_pin(port : GPPort*, pin : GPPin, level : GPLevel) : LibC::Int

  fun gp_port_send_break(port : GPPort*, duration : LibC::Int) : LibC::Int
  fun gp_port_flush(port : GPPort*, direction : LibC::Int) : LibC::Int

  fun gp_port_usb_find_device(port : GPPort*, idvendor : LibC::Int, idproduct : LibC::Int) : LibC::Int
  fun gp_port_usb_find_device_by_class(port : GPPort*, mainclass : LibC::Int, subclass : LibC::Int, protocol : LibC::Int) : LibC::Int
  fun gp_port_usb_clear_halt(port : GPPort*, ep : LibC::Int) : LibC::Int
  fun gp_port_usb_msg_write(port : GPPort*, request : LibC::Int, value : LibC::Int, index : LibC::Int, bytes : LibC::Char*, size : LibC::Int) : LibC::Int
  fun gp_port_usb_msg_read(port : GPPort*, request : LibC::Int, value : LibC::Int, index : LibC::Int, bytes : LibC::Char*, size : LibC::Int) : LibC::Int
  fun gp_port_usb_msg_interface_write(port : GPPort*, request : LibC::Int, value : LibC::Int, index : LibC::Int, bytes : LibC::Char*, size : LibC::Int) : LibC::Int
  fun gp_port_usb_msg_interface_read(port : GPPort*, request : LibC::Int, value : LibC::Int, index : LibC::Int, bytes : LibC::Char*, size : LibC::Int) : LibC::Int
  fun gp_port_usb_msg_class_write(port : GPPort*, request : LibC::Int, value : LibC::Int, index : LibC::Int, bytes : LibC::Char*, size : LibC::Int) : LibC::Int
  fun gp_port_usb_msg_class_read(port : GPPort*, request : LibC::Int, value : LibC::Int, index : LibC::Int, bytes : LibC::Char*, size : LibC::Int) : LibC::Int

  fun gp_port_seek(port : GPPort*, offset : LibC::Int, whence : LibC::Int) : LibC::Int
  fun gp_port_send_scsi_cmd(port : GPPort*, to_dev : LibC::Int, cmd : LibC::Char*, cmd_size : LibC::Int, sense : LibC::Char*, sense_size : LibC::Int, data : LibC::Char*, data_size : LibC::Int) : LibC::Int

  fun gp_port_set_error(port : GPPort*, format : LibC::Char*) : LibC::Int
  fun gp_port_get_error(port : GPPort*) : LibC::Char*

  fun gp_port_info_new(info : GPPortInfo*) : LibC::Int
  fun gp_port_info_get_name(info : GPPortInfo*, name : LibC::Char**) : LibC::Int
  fun gp_port_info_set_name(info : GPPortInfo*, name : LibC::Char*) : LibC::Int
  fun gp_port_info_get_path(info : GPPortInfo*, path : LibC::Char**) : LibC::Int
  fun gp_port_info_set_path(info : GPPortInfo*, path : LibC::Char*) : LibC::Int
  fun gp_port_info_get_type(info : GPPortInfo*, type : GPPortType*) : LibC::Int
  fun gp_port_info_set_type(info : GPPortInfo*, type : GPPortType) : LibC::Int

  fun gp_port_info_get_library_filename(info : GPPortInfo*, lib : LibC::Char**) : LibC::Int
  fun gp_port_info_set_library_filename(info : GPPortInfo*, lib : LibC::Char*) : LibC::Int

  fun gp_port_info_list_new(list : GPPortInfoList**) : LibC::Int
  fun gp_port_info_list_free(list : GPPortInfoList*) : LibC::Int
  fun gp_port_info_list_append(list : GPPortInfoList*, info : GPPortInfo*) : LibC::Int
  fun gp_port_info_list_load(list : GPPortInfoList*) : LibC::Int
  fun gp_port_info_list_count(list : GPPortInfoList*) : LibC::Int
  fun gp_port_info_list_lookup_path(list : GPPortInfoList*, path : LibC::Char*) : LibC::Int
  fun gp_port_info_list_lookup_name(list : GPPortInfoList*, name : LibC::Char*) : LibC::Int
  fun gp_port_info_list_get_info(list : GPPortInfoList*, n : LibC::Int, info : GPPortInfo*) : LibC::Int

  # --- other
  fun gp_port_message_codeset(codeset : LibC::Char*) : LibC::Char*
  fun gp_port_result_as_string(result : LibC::Int) : LibC::Char*
  fun gp_port_library_version(verbose : GPVersionVerbosity) : LibC::Char**

  # gp_context_*
  fun gp_context_new() : GPContext*
  fun gp_context_ref(context : GPContext*)
  fun gp_context_unref(context : GPContext*)
  fun gp_context_set_idle_func(context : GPContext*, func : GPContextIdleFunc, data : Void*)
  fun gp_context_set_progress_funcs(context : GPContext*, start_func : GPContextProgressStartFunc, update_func : GPContextProgressUpdateFunc, stop_func : GPContextProgressStopFunc, data : Void*)
  fun gp_context_set_error_func(context : GPContext*, func : GPContextErrorFunc, data : Void*)
  fun gp_context_set_status_func(context : GPContext*, func : GPContextStatusFunc, data : Void*)
  fun gp_context_set_question_func(context : GPContext*, func : GPContextQuestionFunc, data : Void*)
  fun gp_context_set_cancel_func(context : GPContext*, func : GPContextCancelFunc, data : Void*)
  fun gp_context_set_message_func(context : GPContext*, func : GPContextMessageFunc, data : Void*)
  fun gp_context_idle(context : GPContext*)
  fun gp_context_error(context : GPContext*, format : LibC::Char*)
  fun gp_context_status(context : GPContext*, format : LibC::Char*)
  fun gp_context_message(context : GPContext*, format : LibC::Char*)
  fun gp_context_question(context : GPContext*, format : LibC::Char*) : GPContextFeedback
  fun gp_context_cancel(context : GPContext*) : GPContextFeedback
  fun gp_context_progress_start(context : GPContext*, target : LibC::Float, format : LibC::Char*) : LibC::UInt
  fun gp_context_progress_update(context : GPContext*, id : LibC::UInt, current : LibC::Float)
  fun gp_context_progress_stop(context : GPContext*, id : LibC::UInt)

    # gp_list_*
  fun gp_list_new(list : CameraList**) : LibC::Int
  fun gp_list_ref(list : CameraList*) : LibC::Int
  fun gp_list_unref(list : CameraList*) : LibC::Int
  fun gp_list_free(list : CameraList*) : LibC::Int
  fun gp_list_count(list : CameraList*) : LibC::Int
  fun gp_list_append(list : CameraList*, name : LibC::Char*, value : LibC::Char*) : LibC::Int
  fun gp_list_reset(list : CameraList*) : LibC::Int
  fun gp_list_sort(list : CameraList*) : LibC::Int
  fun gp_list_find_by_name(list : CameraList*, index : LibC::Int*, name : LibC::Char*) : LibC::Int
  fun gp_list_get_name(list : CameraList*, index : LibC::Int, name : LibC::Char**) : LibC::Int
  fun gp_list_get_value(list : CameraList*, index : LibC::Int, value : LibC::Char**) : LibC::Int
  fun gp_list_set_name(list : CameraList*, index : LibC::Int, name : LibC::Char*) : LibC::Int
  fun gp_list_set_value(list : CameraList*, index : LibC::Int, value : LibC::Char*) : LibC::Int
  fun gp_list_populate(list : CameraList*, format : LibC::Char*, count : LibC::Int) : LibC::Int

  # gp_abilities_list_*
  fun gp_abilities_list_new(list : CameraAbilitiesList**) : LibC::Int
  fun gp_abilities_list_free(list : CameraAbilitiesList*) : LibC::Int
  fun gp_abilities_list_load(list : CameraAbilitiesList*, context : GPContext*) : LibC::Int
  fun gp_abilities_list_load_dir(list : CameraAbilitiesList*, dir : LibC::Char*, context : GPContext*) : LibC::Int
  fun gp_abilities_list_reset(list : CameraAbilitiesList*) : LibC::Int
  fun gp_abilities_list_detect(list : CameraAbilitiesList*, info_list : GPPortInfoList*, l : CameraList*, context : GPContext*) : LibC::Int
  fun gp_abilities_list_append(list : CameraAbilitiesList*, abilities : CameraAbilities) : LibC::Int
  fun gp_abilities_list_count(list : CameraAbilitiesList*) : LibC::Int
  fun gp_abilities_list_lookup_model(list : CameraAbilitiesList*, model : LibC::Char*) : LibC::Int
  fun gp_abilities_list_get_abilities(list : CameraAbilitiesList*, index : LibC::Int, abilities : CameraAbilities*) : LibC::Int

  # gp_widget_*
  fun gp_widget_new(type : CameraWidgetType, label : LibC::Char*, widget : CameraWidget**) : LibC::Int
  fun gp_widget_free(widget : CameraWidget*) : LibC::Int
  fun gp_widget_ref(widget : CameraWidget*) : LibC::Int
  fun gp_widget_unref(widget : CameraWidget*) : LibC::Int
  fun gp_widget_changed(widget : CameraWidget*) : LibC::Int

  fun gp_widget_append(widget : CameraWidget*, child : CameraWidget*) : LibC::Int
  fun gp_widget_prepend(widget : CameraWidget*, child : CameraWidget*) : LibC::Int
  fun gp_widget_count_children(widget : CameraWidget*) : LibC::Int

  fun gp_widget_get_child(widget : CameraWidget*, child_number : LibC::Int, child : CameraWidget**) : LibC::Int
  fun gp_widget_get_child_by_label(widget : CameraWidget*, label : LibC::Char*, child : CameraWidget**) : LibC::Int
  fun gp_widget_get_child_by_id(widget : CameraWidget*, id : LibC::Int, child : CameraWidget**) : LibC::Int
  fun gp_widget_get_child_by_name(widget : CameraWidget*, name : LibC::Char*, child : CameraWidget**) : LibC::Int

  fun gp_widget_get_root(widget : CameraWidget*, root : CameraWidget**) : LibC::Int
  fun gp_widget_get_parent(widget : CameraWidget*, parent : CameraWidget**) : LibC::Int

  fun gp_widget_set_value(widget : CameraWidget*, value : Void*) : LibC::Int
  fun gp_widget_get_value(widget : CameraWidget*, value : Void*) : LibC::Int

  fun gp_widget_set_name(widget : CameraWidget*, name : LibC::Char*) : LibC::Int
  fun gp_widget_get_name(widget : CameraWidget*, name : LibC::Char**) : LibC::Int

  fun gp_widget_set_info(widget : CameraWidget*, info : LibC::Char*) : LibC::Int
  fun gp_widget_get_info(widget : CameraWidget*, info : LibC::Char**) : LibC::Int

  fun gp_widget_get_id(widget : CameraWidget*, id : LibC::Int*) : LibC::Int
  fun gp_widget_get_type(widget : CameraWidget*, type : CameraWidgetType*) : LibC::Int
  fun gp_widget_get_label(widget : CameraWidget*, label : LibC::Char**) : LibC::Int

  fun gp_widget_set_range(range : CameraWidget*, low : LibC::Float, high : LibC::Float, increment : LibC::Float) : LibC::Int
  fun gp_widget_get_range(range : CameraWidget*, min : LibC::Float*, max : LibC::Float*, increment : LibC::Float*) : LibC::Int

  fun gp_widget_add_choice(widget : CameraWidget*, choice : LibC::Char*) : LibC::Int
  fun gp_widget_get_choice(widget : CameraWidget*, choice_number : LibC::Int, choice : LibC::Char**) : LibC::Int
  fun gp_widget_count_choices(widget : CameraWidget*) : LibC::Int

  fun gp_widget_set_changed(widget : CameraWidget*, changed : LibC::Int) : LibC::Int
  fun gp_widget_set_readonly(widget : CameraWidget*, readonly : LibC::Int) : LibC::Int
  fun gp_widget_get_readonly(widget : CameraWidget*, readonly : LibC::Int*) : LibC::Int

  # gp_file_*
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

  # gp_camera_*
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

  fun gp_camera_set_port_info(camera : Camera*, info : GPPortInfo) : LibC::Int
  fun gp_camera_get_port_info(camera : Camera*, info : GPPortInfo*) : LibC::Int

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

  fun gp_camera_file_get_info(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, info : CameraFileInfo*, context : GPContext*) : LibC::Int
  fun gp_camera_file_set_info(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, info : CameraFileInfo, context : GPContext*) : LibC::Int

  fun gp_camera_file_get(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, type : CameraFileType, camera_file : CameraFile*, context : GPContext*) : LibC::Int
  fun gp_camera_file_read(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, type : CameraFileType, offset : LibC::UInt64T, buf : LibC::Char*, size : LibC::UInt64T*, context : GPContext*) : LibC::Int
  fun gp_camera_file_delete(camera : Camera*, folder : LibC::Char*, file : LibC::Char*, context : GPContext*) : LibC::Int

  fun gp_camera_set_timeout_funcs(camera : Camera*, start_func : CameraTimeoutStartFunc, stop_func : CameraTimeoutStopFunc, data : Void*)
  fun gp_camera_start_timeout(camera : Camera*, timeout : LibC::UInt, func : CameraTimeoutFunc) : LibC::Int
  fun gp_camera_stop_timeout(camera : Camera*, id : LibC::UInt)

  # --- other
  fun gp_result_as_string(result : LibC::Int) : LibC::Char*
  fun gp_message_codeset(codeset : LibC::Char*) : LibC::Char*
  fun gp_library_version(verbose : GPVersionVerbosity) : LibC::Char**
end
