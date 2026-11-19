require "../spec_helper"

module GPhoto2
  describe CameraFile do
    it "exposes path parts" do
      with_directory_camera do |camera|
        file = camera.blob("/DCIM/sub/b.jpg")
        file.name.should eq "b.jpg"
        file.folder.should eq "/DCIM/sub"
        file.preview?.should be_false
      end
    end

    it "returns file data" do
      with_directory_camera do |camera|
        file = camera.blob("/DCIM/a.jpg")
        file.size.should eq 5
        String.new(file.to_slice).should eq "hello"
      end
    end

    it "returns file info" do
      with_directory_camera do |camera|
        info = camera.blob("/DCIM/a.jpg").info.file
        info.size.should eq 5
        info.mtime.should be_a Time
      end
    end

    describe "#save" do
      it "saves file data to the given path" do
        with_directory_camera do |camera, dir|
          target = File.join(dir, "out", "copy.jpg")
          camera.blob("/DCIM/a.jpg").save(target)
          File.read(target).should eq "hello"
        end
      end
    end

    describe "#delete" do
      it "deletes the file from the camera" do
        with_directory_camera do |camera, dir|
          camera.blob("/DCIM/a.jpg").delete
          File.exists?(File.join(dir, "DCIM", "a.jpg")).should be_false
        end
      end
    end

    describe "#mtime=" do
      it "sets the modification time" do
        with_directory_camera do |camera|
          file = camera.blob("/DCIM/a.jpg")
          time = Time.unix(1_000_000)
          file.mtime = time
          file.mtime.should eq time
        end
      end
    end

    describe "#mime_type=" do
      it "sets the mime type" do
        with_directory_camera do |camera|
          file = camera.blob("/DCIM/a.jpg")
          file.mime_type = "image/jpeg"
          file.mime_type.should eq "image/jpeg"
          file.mime_type = nil
          file.mime_type.should be_nil
        end
      end
    end

    it "compares by camera and path" do
      with_directory_camera do |camera|
        camera.blob("/DCIM/a.jpg").should eq camera.blob("DCIM/a.jpg")
        camera.blob("/DCIM/a.jpg").should_not eq camera.blob("DCIM/sub/b.jpg")
      end
    end

    it "hashes by camera and path" do
      with_directory_camera do |camera|
        Set{camera.blob("/DCIM/a.jpg"), camera.blob("DCIM/a.jpg")}.size.should eq 1
      end
    end

    describe "#data=" do
      it "replaces previously read data" do
        with_directory_camera do |camera|
          file = camera.blob("/DCIM/a.jpg")
          String.new(file.to_slice).should eq "hello"

          file.data = "bye".to_slice
          file.size.should eq 3
          String.new(file.to_slice).should eq "bye"
        end
      end
    end

    describe "#close" do
      it "keeps the file alive while referenced by libgphoto2" do
        with_directory_camera do |camera|
          file = CameraFile.new(camera, "/DCIM/new.jpg")
          file.data = "abc".to_slice

          ptr = file.ptr
          GPhoto2.check! LibGPhoto2.gp_file_ref(ptr)
          file.close

          GPhoto2.check! LibGPhoto2.gp_file_get_data_and_size(ptr, out data, out size)
          String.new(data, size).should eq "abc"
          GPhoto2.check! LibGPhoto2.gp_file_unref(ptr)
        end
      end

      it "discards previously read data" do
        with_directory_camera do |camera|
          file = camera.blob("/DCIM/a.jpg")
          file.to_slice
          file.close
          file.@data_and_size.should be_nil
        end
      end
    end

    describe "#to_s" do
      it "returns the file path" do
        with_directory_camera do |camera|
          file = camera.blob("/DCIM/a.jpg")
          file.to_s.should eq "/DCIM/a.jpg"
          "#{file}".should eq "/DCIM/a.jpg"
        end
      end
    end
  end
end
