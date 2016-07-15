@[Link("libgphoto2_port")]
lib LibGPhoto2Port
  #
  # Enums
  #

  @[Flags]
  enum GPPortType
    Serial
    USB           = (1 << 2)
    Disk
    PTPIP
    USBDiskDirect
    USBSCSI
  end
end
