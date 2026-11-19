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

      it "keeps previously returned widgets usable" do
        with_configured_camera do |camera|
          window = camera.window
          iso = camera[:iso]
          camera.reload

          window.ptr?.should be_truthy
          iso.value.should eq "100"
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

      it "copies the value of a foreign widget" do
        with_configured_camera do |camera|
          widget = build_widget(:text, "owner")
          widget.value = "Jane"
          camera << widget
          camera.save
          FakeDriver.settings["owner"].value.should eq "Jane"
        end
      end

      it "raises for unknown widget" do
        with_configured_camera do |camera|
          expect_raises(KeyError) do
            camera << build_widget(:text, "unknown")
          end
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

      it "returns the value of the block" do
        with_configured_camera do |camera|
          camera.preserving_config { 42 }.should eq 42
          camera.preserving_config(:iso) { camera[:iso].to_s }.should eq "100"
        end
      end

      it "raises on unknown keys" do
        with_configured_camera do |camera|
          called = false
          expect_raises(KeyError) do
            camera.preserving_config(:iso, :nope) { called = true }
          end
          called.should be_false
        end
      end

      it "restores empty values" do
        with_configured_camera do |camera|
          FakeDriver.settings["mode"] = FakeDriver::Setting.new(:radio, "None", %w(None Auto))
          FakeDriver.settings["artist"] = FakeDriver::Setting.new(:text, "")
          camera.reload

          camera.preserving_config do
            camera.update(mode: "Auto", artist: "Jane")
          end
          FakeDriver.settings["mode"].value.should eq "None"
          FakeDriver.settings["artist"].value.should eq ""
        end
      end

      it "does not save unchanged values" do
        with_configured_camera do |camera|
          FakeDriver.settings["mode"] = FakeDriver::Setting.new(:radio, "None", %w(None Auto))
          camera.reload

          camera.preserving_config { }
          FakeDriver.calls[:set_config].should eq 0
        end
      end

      it "raises the original exception when restoring fails" do
        with_configured_camera do |camera|
          expect_raises(::Exception, "oops") do
            camera.preserving_config do
              camera[:iso] = 400
              FakeDriver.fail_set_config = true
              raise "oops"
            end
          end
        end
      end

      it "raises when restoring fails" do
        with_configured_camera do |camera|
          expect_raises(GPhoto2::Error) do
            camera.preserving_config do
              camera[:iso] = 400
              FakeDriver.fail_set_config = true
            end
          end
        end
      end

      it "does not restore read-only values" do
        with_configured_camera do |camera|
          FakeDriver.settings["shots"] = FakeDriver::Setting.new(:text, "10", readonly: true)
          camera.reload

          camera.preserving_config do
            # simulate the camera updating the value on its own
            FakeDriver.settings["shots"] = FakeDriver::Setting.new(:text, "9", readonly: true)
            camera.reload
          end
          FakeDriver.calls[:set_config].should eq 0
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
