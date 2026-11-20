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
  end
end
