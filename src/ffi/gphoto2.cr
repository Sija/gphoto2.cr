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

  fun gp_log_with_source_location (level : GPLogLevel, file : LibC::Char*, line : LibC::Int, func : LibC::Char*, format : LibC::Char*, ...)
  fun gp_log_data(domain : LibC::Char*, data : LibC::Char*, size : LibC::UInt, format : LibC::Char*, ...)

  # gp_setting_*
  fun gp_setting_set(id : LibC::Char*, key : LibC::Char*, value : LibC::Char*) : Int16
  fun gp_setting_get(id : LibC::Char*, key : LibC::Char*, value : LibC::Char*) : Int16

  # gp_port_*
  fun gp_port_new(port : GPPort**) : Int16
  fun gp_port_free(port : GPPort*) : Int16

  fun gp_port_set_info(port : GPPort*, info : GPPortInfo) : Int16
  fun gp_port_get_info(port : GPPort*, info : GPPortInfo*) : Int16

  fun gp_port_open(port : GPPort*) : Int16
  fun gp_port_close(port : GPPort*) : Int16
  fun gp_port_reset(port : GPPort*) : Int16

  fun gp_port_write(port : GPPort*, data : LibC::Char*, size : Int16) : Int16
  fun gp_port_read(port : GPPort*, data : LibC::Char*, size : Int16) : Int16

  fun gp_port_check_int(port : GPPort*, data : LibC::Char*, size : Int16) : Int16
  fun gp_port_check_int_fast(port : GPPort*, data : LibC::Char*, size : Int16) : Int16

  fun gp_port_get_timeout(port : GPPort*, timeout : Int16*) : Int16
  fun gp_port_set_timeout(port : GPPort*, timeout : Int16) : Int16

  fun gp_port_set_settings(port : GPPort*, settings : GPPortSettings) : Int16
  fun gp_port_get_settings(port : GPPort*, settings : GPPortSettings*) : Int16

  fun gp_port_get_pin(port : GPPort*, pin : GPPin, level : GPLevel*) : Int16
  fun gp_port_set_pin(port : GPPort*, pin : GPPin, level : GPLevel) : Int16

  fun gp_port_send_break(port : GPPort*, duration : Int16) : Int16
  fun gp_port_flush(port : GPPort*, direction : Int16) : Int16

  fun gp_port_usb_find_device(port : GPPort*, idvendor : Int16, idproduct : Int16) : Int16
  fun gp_port_usb_find_device_by_class(port : GPPort*, mainclass : Int16, subclass : Int16, protocol : Int16) : Int16
  fun gp_port_usb_clear_halt(port : GPPort*, ep : Int16) : Int16
  fun gp_port_usb_msg_write(port : GPPort*, request : Int16, value : Int16, index : Int16, bytes : LibC::Char*, size : Int16) : Int16
  fun gp_port_usb_msg_read(port : GPPort*, request : Int16, value : Int16, index : Int16, bytes : LibC::Char*, size : Int16) : Int16
  fun gp_port_usb_msg_interface_write(port : GPPort*, request : Int16, value : Int16, index : Int16, bytes : LibC::Char*, size : Int16) : Int16
  fun gp_port_usb_msg_interface_read(port : GPPort*, request : Int16, value : Int16, index : Int16, bytes : LibC::Char*, size : Int16) : Int16
  fun gp_port_usb_msg_class_write(port : GPPort*, request : Int16, value : Int16, index : Int16, bytes : LibC::Char*, size : Int16) : Int16
  fun gp_port_usb_msg_class_read(port : GPPort*, request : Int16, value : Int16, index : Int16, bytes : LibC::Char*, size : Int16) : Int16

  fun gp_port_seek(port : GPPort*, offset : Int16, whence : Int16) : Int16
  fun gp_port_send_scsi_cmd(port : GPPort*, to_dev : Int16, cmd : LibC::Char*, cmd_size : Int16, sense : LibC::Char*, sense_size : Int16, data : LibC::Char*, data_size : Int16) : Int16

  fun gp_port_set_error(port : GPPort*, format : LibC::Char*) : Int16
  fun gp_port_get_error(port : GPPort*) : LibC::Char*

  fun gp_port_info_new(info : GPPortInfo*) : Int16
  fun gp_port_info_get_name(info : GPPortInfo*, name : LibC::Char**) : Int16
  fun gp_port_info_set_name(info : GPPortInfo*, name : LibC::Char*) : Int16
  fun gp_port_info_get_path(info : GPPortInfo*, path : LibC::Char**) : Int16
  fun gp_port_info_set_path(info : GPPortInfo*, path : LibC::Char*) : Int16
  fun gp_port_info_get_type(info : GPPortInfo*, type : GPPortType*) : Int16
  fun gp_port_info_set_type(info : GPPortInfo*, type : GPPortType) : Int16

  fun gp_port_info_get_library_filename(info : GPPortInfo*, lib : LibC::Char**) : Int16
  fun gp_port_info_set_library_filename(info : GPPortInfo*, lib : LibC::Char*) : Int16

  fun gp_port_info_list_new(list : GPPortInfoList**) : Int16
  fun gp_port_info_list_free(list : GPPortInfoList*) : Int16
  fun gp_port_info_list_append(list : GPPortInfoList*, info : GPPortInfo*) : Int16
  fun gp_port_info_list_load(list : GPPortInfoList*) : Int16
  fun gp_port_info_list_count(list : GPPortInfoList*) : Int16
  fun gp_port_info_list_lookup_path(list : GPPortInfoList*, path : LibC::Char*) : Int16
  fun gp_port_info_list_lookup_name(list : GPPortInfoList*, name : LibC::Char*) : Int16
  fun gp_port_info_list_get_info(list : GPPortInfoList*, n : Int16, info : GPPortInfo*) : Int16

  fun gp_port_message_codeset(codeset : LibC::Char*) : LibC::Char*
  fun gp_port_result_as_string(result : Int16) : LibC::Char*
  fun gp_port_library_version(verbose : GPVersionVerbosity) : LibC::Char**

  # gp_context_*
  fun gp_context_new() : GPContext*
  fun gp_context_ref(context : GPContext*)
  fun gp_context_unref(context : GPContext*)
  fun gp_context_set_idle_func(context : GPContext*, func : Void*, data : Void*)
  fun gp_context_set_progress_funcs(context : GPContext*, start_func : Void*, update_func : Void*, stop_func : Void*, data : Void*)
  fun gp_context_set_error_func(context : GPContext*, func : Void*, data : Void*)
  fun gp_context_set_status_func(context : GPContext*, func : Void*, data : Void*)
  fun gp_context_set_question_func(context : GPContext*, func : Void*, data : Void*)
  fun gp_context_set_cancel_func(context : GPContext*, func : Void*, data : Void*)
  fun gp_context_set_message_func(context : GPContext*, func : Void*, data : Void*)
  fun gp_context_idle(context : GPContext*)
  fun gp_context_error(context : GPContext*, format : UInt8*)
  fun gp_context_status(context : GPContext*, format : UInt8*)
  fun gp_context_message(context : GPContext*, format : UInt8*)
  fun gp_context_question(context : GPContext*, format : UInt8*) : GPContextFeedback
  fun gp_context_cancel(context : GPContext*) : GPContextFeedback
  fun gp_context_progress_start(context : GPContext*, target : Float32, format : UInt8*) : UInt16
  fun gp_context_progress_update(context : GPContext*, id : UInt16, current : Float32)
  fun gp_context_progress_stop(context : GPContext*, id : UInt16)

    # gp_list_*
  fun gp_list_new(list : Void**) : Int16
  fun gp_list_ref(list : CameraList*) : Int16
  fun gp_list_unref(list : CameraList*) : Int16
  fun gp_list_free(list : CameraList*) : Int16
  fun gp_list_count(list : CameraList*) : Int16
  fun gp_list_append(list : CameraList*, name : UInt8*, value : UInt8*) : Int16
  fun gp_list_reset(list : CameraList*) : Int16
  fun gp_list_sort(list : CameraList*) : Int16
  fun gp_list_find_by_name(list : CameraList*, index : Void*, name : UInt8*) : Int16
  fun gp_list_get_name(list : CameraList*, index : Int16, name : Void**) : Int16
  fun gp_list_get_value(list : CameraList*, index : Int16, value : Void**) : Int16
  fun gp_list_set_name(list : CameraList*, index : Int16, name : UInt8*) : Int16
  fun gp_list_set_value(list : CameraList*, index : Int16, value : UInt8*) : Int16
  fun gp_list_populate(list : CameraList*, format : UInt8*, count : Int16) : Int16

  # gp_abilities_list_*
  fun gp_abilities_list_new(list : Void**) : Int16
  fun gp_abilities_list_free(list : CameraAbilitiesList*) : Int16
  fun gp_abilities_list_load(list : CameraAbilitiesList*, context : GPContext*) : Int16
  fun gp_abilities_list_load_dir(list : CameraAbilitiesList*, dir : UInt8*, context : GPContext*) : Int16
  fun gp_abilities_list_reset(list : CameraAbilitiesList*) : Int16
  fun gp_abilities_list_detect(list : CameraAbilitiesList*, info_list : Void*, l : CameraList*, context : GPContext*) : Int16
  fun gp_abilities_list_append(list : CameraAbilitiesList*, abilities : CameraAbilities) : Int16
  fun gp_abilities_list_count(list : CameraAbilitiesList*) : Int16
  fun gp_abilities_list_lookup_model(list : CameraAbilitiesList*, model : UInt8*) : Int16
  fun gp_abilities_list_get_abilities(list : CameraAbilitiesList*, index : Int16, abilities : CameraAbilities*) : Int16

  # gp_widget_*
  fun gp_widget_new(type : CameraWidgetType, label : UInt8*, widget : Void**) : Int16
  fun gp_widget_free(widget : CameraWidget*) : Int16
  fun gp_widget_ref(widget : CameraWidget*) : Int16
  fun gp_widget_unref(widget : CameraWidget*) : Int16
  fun gp_widget_append(widget : CameraWidget*, child : CameraWidget*) : Int16
  fun gp_widget_prepend(widget : CameraWidget*, child : CameraWidget*) : Int16
  fun gp_widget_count_children(widget : CameraWidget*) : Int16
  fun gp_widget_get_child(widget : CameraWidget*, child_number : Int16, child : Void**) : Int16
  fun gp_widget_get_child_by_label(widget : CameraWidget*, label : UInt8*, child : Void**) : Int16
  fun gp_widget_get_child_by_id(widget : CameraWidget*, id : Int16, child : Void**) : Int16
  fun gp_widget_get_child_by_name(widget : CameraWidget*, name : UInt8*, child : Void**) : Int16
  fun gp_widget_get_root(widget : CameraWidget*, root : Void**) : Int16
  fun gp_widget_get_parent(widget : CameraWidget*, parent : Void**) : Int16
  fun gp_widget_set_value(widget : CameraWidget*, value : Void*) : Int16
  fun gp_widget_get_value(widget : CameraWidget*, value : Void*) : Int16
  fun gp_widget_set_name(widget : CameraWidget*, name : UInt8*) : Int16
  fun gp_widget_get_name(widget : CameraWidget*, name : Void**) : Int16
  fun gp_widget_set_info(widget : CameraWidget*, info : UInt8*) : Int16
  fun gp_widget_get_info(widget : CameraWidget*, info : Void**) : Int16
  fun gp_widget_get_id(widget : CameraWidget*, id : Void*) : Int16
  fun gp_widget_get_type(widget : CameraWidget*, type : Void*) : Int16
  fun gp_widget_get_label(widget : CameraWidget*, label : Void**) : Int16
  fun gp_widget_set_range(range : CameraWidget*, low : Float32, high : Float32, increment : Float32) : Int16
  fun gp_widget_get_range(range : CameraWidget*, min : Void*, max : Void*, increment : Void*) : Int16
  fun gp_widget_add_choice(widget : CameraWidget*, choice : UInt8*) : Int16
  fun gp_widget_count_choices(widget : CameraWidget*) : Int16
  fun gp_widget_get_choice(widget : CameraWidget*, choice_number : Int16, choice : Void**) : Int16
  fun gp_widget_changed(widget : CameraWidget*) : Int16
  fun gp_widget_set_changed(widget : CameraWidget*, changed : Int16) : Int16
  fun gp_widget_set_readonly(widget : CameraWidget*, readonly : Int16) : Int16
  fun gp_widget_get_readonly(widget : CameraWidget*, readonly : Void*) : Int16

  # gp_file_*
  fun gp_file_new(file : Void**) : Int16
  fun gp_file_new_from_fd(file : Void**, fd : Int16) : Int16
  fun gp_file_new_from_handler(file : Void**, handler : CameraFileHandler*, priv : Void*) : Int16
  fun gp_file_ref(file : CameraFile*) : Int16
  fun gp_file_unref(file : CameraFile*) : Int16
  fun gp_file_free(file : CameraFile*) : Int16
  fun gp_file_set_name(file : CameraFile*, name : UInt8*) : Int16
  fun gp_file_get_name(file : CameraFile*, name : Void**) : Int16
  fun gp_file_set_mime_type(file : CameraFile*, mime_type : UInt8*) : Int16
  fun gp_file_get_mime_type(file : CameraFile*, mime_type : Void**) : Int16
  fun gp_file_set_mtime(file : CameraFile*, mtime : Int32) : Int16
  fun gp_file_get_mtime(file : CameraFile*, mtime : Void*) : Int16
  fun gp_file_detect_mime_type(file : CameraFile*) : Int16
  fun gp_file_adjust_name_for_mime_type(file : CameraFile*) : Int16
  fun gp_file_get_name_by_type(file : CameraFile*, basename : UInt8*, type : CameraFileType, newname : Void**) : Int16
  fun gp_file_set_data_and_size(camerafile : CameraFile*, data : UInt8*, size : UInt32) : Int16
  fun gp_file_get_data_and_size(camerafile : CameraFile*, data : Void**, size : Void*) : Int16
  fun gp_file_open(file : CameraFile*, filename : UInt8*) : Int16
  fun gp_file_save(file : CameraFile*, filename : UInt8*) : Int16
  fun gp_file_clean(file : CameraFile*) : Int16
  fun gp_file_copy(destination : CameraFile*, source : CameraFile*) : Int16
  fun gp_file_append(camerafile : CameraFile*, data : UInt8*, size : UInt32) : Int16
  fun gp_file_slurp(camerafile : CameraFile*, data : UInt8*, size : UInt32, readlen : Void*) : Int16

  # gp_camera_*
  fun gp_camera_autodetect(list : CameraList*, context : GPContext*) : Int16
  fun gp_camera_new(camera : Void**) : Int16
  fun gp_camera_init(camera : Camera*, context : GPContext*) : Int16
  fun gp_camera_exit(camera : Camera*, context : GPContext*) : Int16
  fun gp_camera_ref(camera : Camera*) : Int16
  fun gp_camera_unref(camera : Camera*) : Int16
  fun gp_camera_free(camera : Camera*) : Int16
  fun gp_camera_get_storageinfo(camera : Camera*, void : Void**, void : Void*, context : GPContext*) : Int16

  fun gp_camera_get_summary(camera : Camera*, summary : CameraText*, context : GPContext*) : Int16
  fun gp_camera_get_manual(camera : Camera*, manual : CameraText*, context : GPContext*) : Int16
  fun gp_camera_get_about(camera : Camera*, about : CameraText*, context : GPContext*) : Int16

  fun gp_camera_set_abilities(camera : Camera*, abilities : CameraAbilities) : Int16
  fun gp_camera_get_abilities(camera : Camera*, abilities : CameraAbilities*) : Int16
  fun gp_camera_set_port_info(camera : Camera*, info : Void*) : Int16
  fun gp_camera_get_port_info(camera : Camera*, info : Void*) : Int16
  fun gp_camera_set_port_speed(camera : Camera*, speed : Int16) : Int16
  fun gp_camera_get_port_speed(camera : Camera*) : Int16

  fun gp_camera_capture(camera : Camera*, type : CameraCaptureType, path : CameraFilePath*, context : GPContext*) : Int16
  fun gp_camera_capture_preview(camera : Camera*, file : CameraFile*, context : GPContext*) : Int16
  fun gp_camera_trigger_capture(camera : Camera*, context : GPContext*) : Int16
  fun gp_camera_wait_for_event(camera : Camera*, timeout : Int16, eventtype : Void*, eventdata : Void**, context : GPContext*) : Int16

  fun gp_camera_get_config(camera : Camera*, window : Void**, context : GPContext*) : Int16
  fun gp_camera_list_config(camera : Camera*, list : CameraList*, context : GPContext*) : Int16
  fun gp_camera_get_single_config(camera : Camera*, name : UInt8*, widget : Void**, context : GPContext*) : Int16
  fun gp_camera_set_config(camera : Camera*, window : CameraWidget*, context : GPContext*) : Int16
  fun gp_camera_set_single_config(camera : Camera*, name : UInt8*, widget : CameraWidget*, context : GPContext*) : Int16

  fun gp_camera_folder_list_files   (camera : Camera*, folder : UInt8*, list : CameraList*, context : GPContext*) : Int16
  fun gp_camera_folder_list_folders (camera : Camera*, folder : UInt8*, list : CameraList*, context : GPContext*) : Int16
  fun gp_camera_folder_delete_all   (camera : Camera*, folder : UInt8*, context : GPContext*) : Int16
  fun gp_camera_folder_put_file     (camera : Camera*, folder : UInt8*, filename : UInt8*, type : CameraFileType, file : CameraFile*, context : GPContext*) : Int16
  fun gp_camera_folder_make_dir     (camera : Camera*, folder : UInt8*, name : UInt8*, context : GPContext*) : Int16
  fun gp_camera_folder_remove_dir   (camera : Camera*, folder : UInt8*, name : UInt8*, context : GPContext*) : Int16

  fun gp_camera_file_get_info       (camera : Camera*, folder : UInt8*, file : UInt8*, info : Void*, context : GPContext*) : Int16
  fun gp_camera_file_set_info       (camera : Camera*, folder : UInt8*, file : UInt8*, info : Int32, context : GPContext*) : Int16
  fun gp_camera_file_get            (camera : Camera*, folder : UInt8*, file : UInt8*, type : CameraFileType, camera_file : CameraFile*, context : GPContext*) : Int16
  fun gp_camera_file_read           (camera : Camera*, folder : UInt8*, file : UInt8*, type : CameraFileType, offset : UInt64, buf : UInt8*, size : Void*, context : GPContext*) : Int16
  fun gp_camera_file_delete         (camera : Camera*, folder : UInt8*, file : UInt8*, context : GPContext*) : Int16

  fun gp_camera_set_timeout_funcs   (camera : Camera*, start_func : Void*, stop_func : Void*, data : Void*)
  fun gp_camera_start_timeout       (camera : Camera*, timeout : UInt16, func : Void*) : Int16
  fun gp_camera_stop_timeout        (camera : Camera*, id : UInt16)

  # --- other
  fun gp_message_codeset  (codeset : LibC::Char*) : LibC::Char*
  fun gp_result_as_string (result : LibC::Int) : LibC::Char*
  fun gp_library_version  (verbose : GPVersionVerbosity) : LibC::Char**
end
