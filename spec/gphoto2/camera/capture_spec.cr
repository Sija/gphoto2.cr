require "../../spec_helper"

module GPhoto2
  describe Camera::Capture do
    describe "#capture" do
      it "returns the captured file" do
        with_fake_camera do |camera|
          file = camera.capture
          file.path.should eq Path.posix("/DCIM/a.jpg")
          String.new(file.to_slice).should eq "hello"
        end
      end

      it "keeps the files captured to the internal RAM, before they're evicted" do
        with_fake_camera do |camera|
          FakeDriver.capture_path = "/capt0000.jpg"
          cache_file(camera, "/capt0000.jpg", "in RAM")

          file = camera.capture
          # libgphoto2 keeps only a couple of files cached
          camera.filesystem_reset
          String.new(file.to_slice).should eq "in RAM"

          io = IO::Memory.new
          file.write_to(io)
          io.to_s.should eq "in RAM"
        end
      end

      it "doesn't try reading the files captured to the internal RAM from the camera" do
        with_fake_camera do |camera|
          FakeDriver.capture_path = "/capt0000.jpg"
          cache_file(camera, "/capt0000.jpg", "in RAM")
          stub = stub_file_read(camera, "on the camera".to_slice)

          file = camera.capture
          String.new(file.read).should eq "in RAM"
          file.write_to(IO::Memory.new)
          stub.reads.should eq 0
        end
      end

      it "leaves the files not available right away to be downloaded later on" do
        with_fake_camera do |camera|
          FakeDriver.capture_path = "/capt0000.jpg"
          file = camera.capture
          file.path.should eq Path.posix("/capt0000.jpg")

          expect_raises(GPhoto2::Error) do
            file.to_slice
          end
        end
      end

      it "doesn't download the files stored on the camera storages right away" do
        with_fake_camera do |camera|
          file = camera.capture
          file.@data_and_size.should be_nil
        end
      end

      it "raises when the driver does not report the captured file path" do
        with_fake_camera do |camera|
          FakeDriver.capture_path = nil
          expect_raises(GPhoto2::Error, "Camera did not report the captured file path") do
            camera.capture
          end
        end
      end

      it "saves dirty configuration first" do
        with_fake_camera do |camera|
          FakeDriver.settings["iso"] = FakeDriver::Setting.new(:text, "100")
          camera[:iso] = 200
          camera.capture
          FakeDriver.settings["iso"].value.should eq "200"
        end
      end
    end

    describe "#trigger" do
      it "triggers a capture" do
        with_fake_camera do |camera|
          camera.trigger
          FakeDriver.calls[:trigger_capture].should eq 1
        end
      end
    end

    describe "#preview" do
      it "returns the preview file" do
        with_fake_camera do |camera|
          file = camera.preview
          file.preview?.should be_true
          String.new(file.to_slice).should eq "preview"
        end
      end

      it "names the preview after the mime type of its data" do
        with_fake_camera do |camera|
          FakeDriver.preview_mime_type = LibGPhoto2::GP_MIME_PPM
          file = camera.preview
          file.preview?.should be_true
          file.name.should eq "capture_preview.ppm"
        end
      end

      it "keeps the default name for an unknown mime type" do
        with_fake_camera do |camera|
          camera.preview.name.should eq CameraFile::PREVIEW_FILENAME
        end
      end
    end
  end
end
