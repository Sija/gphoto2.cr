require "./spec_helper"

# Ensures enum values match the ones defined in libgphoto2 headers.
describe "libgphoto2 bindings" do
  it "allocates new port info" do
    GPhoto2.check! LibGPhoto2Port.gp_port_info_new(out info)
    info.null?.should be_false
    GPhoto2.check! LibGPhoto2Port.gp_port_info_set_path(info, "disk:/tmp")
    GPhoto2.check! LibGPhoto2Port.gp_port_info_get_path(info, out path)
    String.new(path).should eq "disk:/tmp"
  end

  it "defines all camera event types" do
    LibGPhoto2::CameraEventType::FileChanged.value.should eq 5
  end

  it "defines all port types" do
    LibGPhoto2Port::GPPortType::USBSCSI.value.should eq 1 << 6
    LibGPhoto2Port::GPPortType::IP.value.should eq 1 << 7
  end

  it "defines all log levels" do
    LibGPhoto2::GPLogLevel::Data.value.should eq 3
  end

  it "defines file info fields" do
    LibGPhoto2::CameraFileInfoFields::Size.value.should eq 1 << 2
    LibGPhoto2::CameraFileInfoFields::Mtime.value.should eq 1 << 7
  end

  it "defines file operations" do
    LibGPhoto2::CameraFileOperation::Delete.value.should eq 1 << 1
    LibGPhoto2::CameraFileOperation::EXIF.value.should eq 1 << 6
  end

  it "defines folder operations" do
    LibGPhoto2::CameraFolderOperation::DeleteAll.value.should eq 1 << 0
    LibGPhoto2::CameraFolderOperation::RemoveDir.value.should eq 1 << 3
  end
end
