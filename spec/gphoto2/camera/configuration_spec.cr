require "../../spec_helper"

module GPhoto2
  private def self.with_configured_camera(&)
    with_fake_camera do |camera|
      FakeDriver.settings["iso"] = FakeDriver::Setting.new(:radio, "100", %w(100 200 400))
      FakeDriver.settings["owner"] = FakeDriver::Setting.new(:text, "John")
      FakeDriver.settings["flash"] = FakeDriver::Setting.new(:toggle, "0")
      FakeDriver.settings["serialnumber"] = FakeDriver::Setting.new(:text, "SN123", readonly: true)
      yield camera
    end
  end

  describe Camera::Configuration do
    describe "#config" do
      it "returns a flat hash of widgets" do
        with_configured_camera do |camera|
          camera.config.keys.should eq %w(iso owner flash serialnumber)
          camera.config["iso"].should be_a CameraWidget::Radio
        end
      end

      it "is memoized" do
        with_configured_camera do |camera|
          camera.config
          camera.config
          FakeDriver.calls[:get_config].should eq 1
        end
      end
    end

    describe "#window" do
      it "returns the root widget" do
        with_configured_camera do |camera|
          camera.window.name.should eq "main"
        end
      end
    end

    describe "#[]" do
      it "returns widget by key" do
        with_configured_camera do |camera|
          camera[:iso].value.should eq "100"
          camera["owner"].value.should eq "John"
          camera[:missing]?.should be_nil
          expect_raises(KeyError) { camera[:missing] }
        end
      end
    end

    describe "#[]=" do
      it "marks configuration as dirty" do
        with_configured_camera do |camera|
          camera.dirty?.should be_false
          camera[:iso] = 400
          camera.dirty?.should be_true
          camera[:iso].value.should eq "400"
        end
      end
    end

    describe "#save" do
      it "saves the configuration only when dirty" do
        with_configured_camera do |camera|
          camera.save.should be_false
          FakeDriver.calls[:set_config].should eq 0

          camera[:iso] = 200
          camera.save.should be_true
          camera.dirty?.should be_false
          FakeDriver.settings["iso"].value.should eq "200"
          FakeDriver.calls[:set_config].should eq 1
        end
      end
    end

    describe "#update" do
      it "updates and saves given attributes" do
        with_configured_camera do |camera|
          camera.update(iso: 400, owner: "Jane").should be_true
          FakeDriver.settings["iso"].value.should eq "400"
          FakeDriver.settings["owner"].value.should eq "Jane"
        end
      end

      it "accepts a hash" do
        with_configured_camera do |camera|
          camera.update({"flash" => true})
          FakeDriver.settings["flash"].value.should eq "1"
        end
      end
    end

    describe "#reload" do
      it "discards unsaved changes" do
        with_configured_camera do |camera|
          camera[:iso] = 400
          camera.reload
          camera.dirty?.should be_false
          camera[:iso].value.should eq "100"
        end
      end
    end

    describe "#<<" do
      it "marks configuration as dirty" do
        with_configured_camera do |camera|
          iso = camera[:iso].as_radio
          iso.value = "200"
          camera << iso
          camera.dirty?.should be_true
          camera.save
          FakeDriver.settings["iso"].value.should eq "200"
        end
      end
    end

    describe "#preserving_config" do
      it "restores the original values" do
        with_configured_camera do |camera|
          camera.preserving_config do
            camera.update(iso: 400, owner: "Jane")
          end
          FakeDriver.settings["iso"].value.should eq "100"
          FakeDriver.settings["owner"].value.should eq "John"
        end
      end

      it "restores only the given keys" do
        with_configured_camera do |camera|
          camera.preserving_config(:iso) do
            camera.update(iso: 400, owner: "Jane")
          end
          FakeDriver.settings["iso"].value.should eq "100"
          FakeDriver.settings["owner"].value.should eq "Jane"
        end
      end

      it "restores the original values when the block raises" do
        with_configured_camera do |camera|
          expect_raises(::Exception, "oops") do
            camera.preserving_config do
              camera.update(iso: 400)
              raise "oops"
            end
          end
          FakeDriver.settings["iso"].value.should eq "100"
        end
      end
    end

    describe "#serialnumber" do
      it "returns the serial number" do
        with_configured_camera do |camera|
          camera.serialnumber.should eq "SN123"
        end
      end
    end
  end
end
