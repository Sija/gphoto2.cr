require "../spec_helper"

module GPhoto2
  private def self.build_camera_file_path(folder, name)
    path = LibGPhoto2::CameraFilePath.new
    path.folder.to_unsafe.copy_from(folder.to_unsafe, folder.bytesize)
    path.name.to_unsafe.copy_from(name.to_unsafe, name.bytesize)
    CameraFilePath.new(path)
  end

  describe CameraFilePath do
    it "reads name and folder" do
      path = build_camera_file_path("/DCIM", "a.jpg")
      path.folder.should eq "/DCIM"
      path.name.should eq "a.jpg"
    end

    it "handles names filling the whole buffer" do
      name = "a" * 128
      path = build_camera_file_path("/DCIM", name)
      path.name.should eq name
      path.folder.should eq "/DCIM"
    end

    it "converts to a posix path" do
      build_camera_file_path("/DCIM", "a.jpg").to_path
        .should eq Path.posix("/DCIM/a.jpg")
    end

    it "compares by value" do
      build_camera_file_path("/DCIM", "a.jpg")
        .should eq build_camera_file_path("/DCIM", "a.jpg")
      build_camera_file_path("/DCIM", "a.jpg")
        .should_not eq build_camera_file_path("/DCIM", "b.jpg")
    end
  end
end
