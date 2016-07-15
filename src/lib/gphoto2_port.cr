require "./gphoto2_port/*"

@[Link("libgphoto2_port")]
lib LibGPhoto2Port
  #
  # Constants
  #

  GP_PORT_MAX_BUF_LEN = 4096

  #
  # Enums
  #

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

  enum GPVersionVerbosity
    Short
    Verbose
  end

  #
  # Aliases
  #

  alias GPPortPrivateLibrary = Void*
  alias GPPortPrivateCore = Void*

  #
  # Structs
  #

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

  #
  # Functions
  #

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

  fun gp_port_message_codeset(codeset : LibC::Char*) : LibC::Char*
  fun gp_port_result_as_string(result : LibC::Int) : LibC::Char*
  fun gp_port_library_version(verbose : GPVersionVerbosity) : LibC::Char**
end
