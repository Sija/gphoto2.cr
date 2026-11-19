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
    end
  end
end
