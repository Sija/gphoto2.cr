require "../spec_helper"

module GPhoto2
  describe Camera do
    it "exposes model and port" do
      camera = Camera.new("Directory Browse", "disk:/tmp")
      camera.model.should eq "Directory Browse"
      camera.port.should eq "disk:/tmp"
    end

    it "is lazily initialized" do
      camera = Camera.new("Directory Browse", "disk:/tmp")
      camera.ptr?.should be_falsey
      camera.ptr.null?.should be_false
      camera.close
      camera.ptr?.should be_falsey
    end

    it "compares by model and port" do
      Camera.new("A", "disk:/a").should eq Camera.new("A", "disk:/a")
      Camera.new("A", "disk:/a").should_not eq Camera.new("A", "disk:/b")
      Camera.new("A", "disk:/a").should_not eq Camera.new("B", "disk:/a")
    end

    it "hashes by model and port" do
      Camera.new("A", "disk:/a").hash.should eq Camera.new("A", "disk:/a").hash
      Set{Camera.new("A", "disk:/a"), Camera.new("A", "disk:/a")}.size.should eq 1
    end

    describe "#abilities" do
      it "returns abilities of the camera model" do
        with_directory_camera do |camera|
          camera.abilities.folder_operations.make_dir?.should be_true
        end
      end
    end

    it "looks up abilities and port info without initializing the camera" do
      camera = Camera.new(DIRECTORY_CAMERA_MODEL, "disk:/tmp")
      camera.can?(:capture_image).should be_false
      camera.port_info.path.should eq "disk:/tmp"
      camera.ptr?.should be_nil
    end

    describe "#can?" do
      it "checks camera operations" do
        with_directory_camera do |camera|
          camera.can?(:capture_image).should be_false
          camera.can?(:config).should be_false
        end
      end
    end

    describe "#port_info" do
      it "returns port info of the camera port" do
        with_directory_camera do |camera, dir|
          camera.port_info.path.should eq "disk:#{dir}"
          camera.port_info.type.disk?.should be_true
        end
      end
    end

    describe "#ptr" do
      it "raises on unknown model" do
        camera = Camera.new("No Such Camera 9000", "disk:/tmp")
        expect_raises(GPhoto2::Error) { camera.ptr }
        camera.ptr?.should be_nil
      end

      it "keeps raising on subsequent calls after a failure" do
        camera = Camera.new("No Such Camera 9000", "disk:/tmp")
        2.times do
          expect_raises(GPhoto2::Error) { camera.ptr }
        end
      end
    end

    describe "#close" do
      it "discards the closed context" do
        with_directory_camera do |camera|
          context = camera.context
          camera.close
          context.ptr?.should be_falsey

          camera.context.should_not be context
          camera.context.ptr?.should be_truthy
        end
      end

      it "allows the camera to be reused" do
        with_directory_camera do |camera|
          (camera / "DCIM").files.size.should eq 1
          camera.close
          (camera / "DCIM").files.size.should eq 1
        end
      end
    end

    describe "#exit" do
      it "does not initialize the camera" do
        camera = Camera.new(DIRECTORY_CAMERA_MODEL, "disk:/tmp")
        camera.exit
        camera.ptr?.should be_falsey
      end

      it "allows the camera to be reused" do
        with_directory_camera do |camera|
          (camera / "DCIM").files.size.should eq 1
          camera.exit
          (camera / "DCIM").files.size.should eq 1
        end
      end
    end

    describe ".open" do
      it "closes the camera after the block" do
        captured = nil
        Camera.open(DIRECTORY_CAMERA_MODEL, "disk:/tmp") do |camera|
          camera.ptr
          camera.ptr?.should be_truthy
          captured = camera
        end
        captured.not_nil!.ptr?.should be_falsey
      end
    end

    describe "#autorelease" do
      it "closes the camera even when the block raises" do
        camera = Camera.new(DIRECTORY_CAMERA_MODEL, "disk:/tmp")
        expect_raises(::Exception, "oops") do
          camera.autorelease do
            camera.ptr
            raise "oops"
          end
        end
        camera.ptr?.should be_falsey
      end
    end

    describe "#serialnumber" do
      it "returns nil when configuration is not supported" do
        with_directory_camera do |camera|
          camera.serialnumber.should be_nil
        end
      end
    end

    describe "#id" do
      it "is stable for the same model and port" do
        with_fixture_dir do |dir|
          a = Camera.new(DIRECTORY_CAMERA_MODEL, "disk:#{dir}")
          b = Camera.new(DIRECTORY_CAMERA_MODEL, "disk:#{dir}")
          a.id.should eq b.id
          a.close
          b.close
        end
      end

      it "differs between ports" do
        with_fixture_dir do |dir|
          a = Camera.new(DIRECTORY_CAMERA_MODEL, "disk:#{dir}")
          b = Camera.new(DIRECTORY_CAMERA_MODEL, "disk:#{dir}/DCIM")
          a.id.should_not eq b.id
          a.close
          b.close
        end
      end
    end

    describe "#filesystem" do
      it "returns the root folder by default" do
        with_directory_camera do |camera|
          camera.filesystem.root?.should be_true
        end
      end

      it "makes relative paths absolute and normalizes them" do
        with_directory_camera do |camera|
          camera.filesystem("DCIM/sub/..").path.should eq Path.posix("/DCIM")
          (camera / "DCIM").path.should eq Path.posix("/DCIM")
        end
      end
    end

    describe "#blob" do
      it "returns a file by its path" do
        with_directory_camera do |camera|
          file = camera.blob("DCIM/a.jpg")
          file.path.should eq Path.posix("/DCIM/a.jpg")
          file.name.should eq "a.jpg"
          String.new(file.to_slice).should eq "hello"
        end
      end
    end

    describe ".where" do
      it "accepts string filters" do
        Camera.where(model: "No Such Camera", port: "usb:999,999").should be_empty
      end

      it "accepts regex filters" do
        Camera.where(model: /^No Such Camera$/, port: /^usb:999/).should be_empty
      end
    end
  end
end
