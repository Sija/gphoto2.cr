require "../../spec_helper"

module GPhoto2
  describe Camera::Event do
    describe "#wait" do
      it "waits for an event" do
        with_directory_camera do |camera|
          # "Directory Browse" driver doesn't support events,
          # yet this ensures the code path compiles and calls into the library.
          error = expect_raises(GPhoto2::Error) do
            camera.wait(10.milliseconds)
          end
          error.code.should eq LibGPhoto2::GP_ERROR_NOT_SUPPORTED
        end
      end
    end

    describe "#wait" do
      it "returns a timeout event" do
        with_fake_camera do |camera|
          event = camera.wait(10.milliseconds)
          event.type.timeout?.should be_true
          event.data.should be_nil
        end
      end

      it "returns no data for events with untouched data" do
        with_fake_camera do |camera|
          FakeDriver.events << FakeDriver::FakeEvent.new(:timeout, untouched_data: true)
          event = camera.wait
          event.type.timeout?.should be_true
          event.data.should be_nil
        end
      end

      it "returns a timeout event when the driver leaves it untouched" do
        with_fake_camera do |camera|
          FakeDriver.events << FakeDriver::FakeEvent.new(:file_added, untouched_type: true, untouched_data: true)
          event = camera.wait
          event.type.timeout?.should be_true
          event.data.should be_nil
        end
      end

      it "accepts timeouts out of the C int range" do
        with_fake_camera do |camera|
          camera.wait(Time::Span::MAX).type.timeout?.should be_true
          FakeDriver.last_timeout.should eq Int32::MAX
          camera.wait(-1.second).type.timeout?.should be_true
          FakeDriver.last_timeout.should eq 0
          camera.wait(1.5.seconds)
          FakeDriver.last_timeout.should eq 1500
        end
      end

      it "returns no data for file/folder events without a path" do
        with_fake_camera do |camera|
          {CameraEvent::Type::FileAdded, CameraEvent::Type::FileChanged, CameraEvent::Type::FolderAdded}.each do |type|
            FakeDriver.events << FakeDriver::FakeEvent.new(type)
            event = camera.wait
            event.type.should eq type
            event.data.should be_nil
          end
        end
      end

      it "returns no data for file events without a file name" do
        with_fake_camera do |camera|
          {"/", "/DCIM/"}.each do |path|
            FakeDriver.events << FakeDriver::FakeEvent.new(CameraEvent::Type::FileAdded, path)
            event = camera.wait
            event.type.file_added?.should be_true
            event.data.should be_nil
          end
        end
      end

      it "returns file added event" do
        with_fake_camera do |camera|
          FakeDriver.events << FakeDriver::FakeEvent.new(:file_added, "/DCIM/a.jpg")
          event = camera.wait
          event.type.file_added?.should be_true
          event.data.should eq camera.blob("/DCIM/a.jpg")
        end
      end

      it "returns file changed event" do
        with_fake_camera do |camera|
          FakeDriver.events << FakeDriver::FakeEvent.new(:file_changed, "/DCIM/a.jpg")
          camera.wait.data.should eq camera.blob("/DCIM/a.jpg")
        end
      end

      it "returns folder added event" do
        with_fake_camera do |camera|
          FakeDriver.events << FakeDriver::FakeEvent.new(:folder_added, "/DCIM/sub")
          camera.wait.data.should eq camera / "DCIM/sub"
        end
      end
    end

    describe "#wait_for" do
      it "skips events of other types" do
        with_fake_camera do |camera|
          FakeDriver.events << FakeDriver::FakeEvent.new(:capture_complete)
          FakeDriver.events << FakeDriver::FakeEvent.new(:file_added, "/DCIM/a.jpg")
          event = camera.wait_for(:file_added)
          event.data.should eq camera.blob("/DCIM/a.jpg")
          FakeDriver.calls[:wait_for_event].should eq 2
        end
      end

      it "raises after the timeout" do
        with_fake_camera do |camera|
          error = expect_raises(GPhoto2::Error) do
            camera.wait_for(:file_added, 50.milliseconds)
          end
          error.code.should eq LibGPhoto2::GP_ERROR_TIMEOUT
        end
      end
    end

    describe "#wait_for" do
      it "waits for an event of the given type" do
        with_directory_camera do |camera|
          expect_raises(GPhoto2::Error) do
            camera.wait_for(:file_added, 10.milliseconds)
          end
        end
      end
    end
  end
end
