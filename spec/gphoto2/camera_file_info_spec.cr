require "../spec_helper"

module GPhoto2
  describe CameraFileInfo::File do
    describe "#mtime" do
      it "returns the modification time" do
        info = LibGPhoto2::CameraFileInfoFile.new(fields: CameraFileInfo::Fields::Mtime, mtime: 1_000_000)
        CameraFileInfo::File.new(pointerof(info)).mtime.should eq Time.unix(1_000_000)
      end

      it "returns nil when not set" do
        info = LibGPhoto2::CameraFileInfoFile.new(mtime: 1_000_000)
        CameraFileInfo::File.new(pointerof(info)).mtime.should be_nil
      end

      it "returns nil for timestamps out of range" do
        info = LibGPhoto2::CameraFileInfoFile.new(fields: CameraFileInfo::Fields::Mtime, mtime: Int64::MAX)
        CameraFileInfo::File.new(pointerof(info)).mtime.should be_nil
      end
    end

    describe "#width and #height" do
      it "return the dimensions" do
        info = LibGPhoto2::CameraFileInfoFile.new(fields: CameraFileInfo::Fields::Width | CameraFileInfo::Fields::Height, width: 640, height: 480)
        file = CameraFileInfo::File.new(pointerof(info))
        file.width.should eq 640
        file.height.should eq 480
      end

      it "return nil for values out of range" do
        info = LibGPhoto2::CameraFileInfoFile.new(fields: CameraFileInfo::Fields::Width | CameraFileInfo::Fields::Height, width: UInt32::MAX, height: UInt32::MAX)
        file = CameraFileInfo::File.new(pointerof(info))
        file.width.should be_nil
        file.height.should be_nil
      end
    end
  end

  describe CameraFileInfo::Preview do
    describe "#width and #height" do
      it "return nil for values out of range" do
        info = LibGPhoto2::CameraFileInfoPreview.new(fields: CameraFileInfo::Fields::Width | CameraFileInfo::Fields::Height, width: UInt32::MAX, height: UInt32::MAX)
        preview = CameraFileInfo::Preview.new(pointerof(info))
        preview.width.should be_nil
        preview.height.should be_nil
      end
    end
  end
end
