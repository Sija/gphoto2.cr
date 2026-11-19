require "../spec_helper"

module GPhoto2
  describe CameraFile do
    it "allocates memory lazily" do
      with_directory_camera do |camera|
        files = (camera / "DCIM").files
        files.first.ptr?.should be_nil
        files.first.size.should eq 5
        files.first.ptr?.should be_truthy
      end
    end

    it "makes relative paths absolute and normalizes them" do
      with_directory_camera do |camera|
        file = CameraFile.new(camera, "DCIM/sub/../a.jpg")
        file.path.should eq Path.posix("/DCIM/a.jpg")
        file.should eq camera.blob("/DCIM/a.jpg")
        file.size.should eq 5
      end
    end

    it "rejects paths pointing to the root folder" do
      with_directory_camera do |camera|
        ["", "/", "DCIM/..", Path.posix("/")].each do |path|
          expect_raises(ArgumentError, "Invalid file path") do
            CameraFile.new(camera, path)
          end
        end
        expect_raises(ArgumentError, "Invalid file path") do
          camera.blob("/")
        end
      end
    end

    it "is a preview only when created without a path" do
      with_directory_camera do |camera|
        CameraFile.new(camera).preview?.should be_true
        CameraFile.new(camera, CameraFile::PREVIEW_FILENAME).preview?.should be_false
      end
    end

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

    describe "#read" do
      [0, 5, CameraFile::BUFFER_SIZE, CameraFile::BUFFER_SIZE * 2, CameraFile::BUFFER_SIZE * 2 + 123].each do |size|
        it "reads #{size} bytes in chunks" do
          with_directory_camera do |camera|
            data = Bytes.new(size) { |i| (i % 251).to_u8 }
            stub_file_read(camera, data)
            camera.blob("/DCIM/a.jpg").read.should eq data
          end
        end

        it "reads #{size} bytes with a matching reported size" do
          with_directory_camera do |camera|
            data = Bytes.new(size) { |i| (i % 251).to_u8 }
            stub_file_read(camera, data, reported_size: size.to_u64)
            camera.blob("/DCIM/a.jpg").read.should eq data
          end
        end
      end

      it "keeps reading after short reads" do
        with_directory_camera do |camera|
          data = Bytes.new(3000) { |i| (i % 251).to_u8 }
          stub_file_read(camera, data, max_read_size: 1000_u64)
          camera.blob("/DCIM/a.jpg").read.should eq data
        end
      end

      it "keeps reading after short reads with a matching reported size" do
        with_directory_camera do |camera|
          data = Bytes.new(3000) { |i| (i % 251).to_u8 }
          stub_file_read(camera, data, reported_size: data.size.to_u64, max_read_size: 1000_u64)
          camera.blob("/DCIM/a.jpg").read.should eq data
        end
      end

      it "reads files larger than their reported size" do
        with_directory_camera do |camera|
          data = Bytes.new(CameraFile::BUFFER_SIZE * 2 + 123) { |i| (i % 251).to_u8 }
          stub_file_read(camera, data, reported_size: 10_u64)
          camera.blob("/DCIM/a.jpg").read.should eq data
        end
      end

      it "allocates only as much memory as needed for the reported size" do
        with_directory_camera do |camera|
          data = Bytes.new(CameraFile::BUFFER_SIZE * 2 + 123) { |i| (i % 251).to_u8 }
          stub_file_read(camera, data, reported_size: data.size.to_u64)
          bytes = camera.blob("/DCIM/a.jpg").read
          bytes.should eq data
          LibGC.size(bytes.to_unsafe).should be < data.size + 64 * 1024
        end
      end

      it "does not allocate memory upfront for bogus reported sizes" do
        with_directory_camera do |camera|
          stub_file_read(camera, "hello".to_slice, reported_size: 0xFFFFFFFF_u64)
          heap_size = GC.stats.heap_size
          camera.blob("/DCIM/a.jpg").read.should eq "hello".to_slice
          (GC.stats.heap_size - heap_size).should be <= CameraFile::MAX_PREALLOCATED_SIZE * 2
        end
      end

      it "does not ignore cancellation while looking up the file size" do
        with_directory_camera do |camera|
          stub_file_read(camera, "hello".to_slice, reported_size: 5_u64)
          # Cancel only the first operation, which is the file info lookup
          checks = 0
          camera.context.cancel_callback = -> { (checks += 1) == 1 }

          error = expect_raises(GPhoto2::Error) do
            camera.blob("/DCIM/a.jpg").read
          end
          error.code.should eq LibGPhoto2::GP_ERROR_CANCEL
        end
      end

      it "does not overflow on the maximum reported size" do
        with_directory_camera do |camera|
          stub_file_read(camera, "hello".to_slice, reported_size: UInt64::MAX)
          camera.blob("/DCIM/a.jpg").read.should eq "hello".to_slice
        end
      end

      it "does not hold on to unused memory when the reported size is too large" do
        with_directory_camera do |camera|
          data = "hello".to_slice
          stub_file_read(camera, data, reported_size: 10_000_000_u64)
          bytes = camera.blob("/DCIM/a.jpg").read
          bytes.should eq data
          LibGC.size(bytes.to_unsafe).should be < 1024
        end
      end
    end

    describe "#to_slice" do
      it "returns a copy of the data, valid after the file is closed" do
        with_directory_camera do |camera|
          file = camera.blob("/DCIM/a.jpg")
          bytes = file.to_slice
          bytes.to_unsafe.should_not eq file.data
          file.close
          String.new(bytes).should eq "hello"
        end
      end
    end

    describe "#write_to" do
      it "writes file data to the given IO" do
        with_directory_camera do |camera|
          io = IO::Memory.new
          camera.blob("/DCIM/a.jpg").write_to(io)
          io.to_s.should eq "hello"
        end
      end
    end

    describe "#save" do
      it "saves file data under its name by default" do
        with_directory_camera do |camera, dir|
          Dir.cd(File.join(dir, "DCIM", "sub")) do
            camera.blob("/DCIM/a.jpg").save
          end
          File.read(File.join(dir, "DCIM", "sub", "a.jpg")).should eq "hello"
        end
      end

      it "names preview files after the preview filename" do
        with_directory_camera do |camera|
          file = CameraFile.new(camera)
          file.preview?.should be_true
          file.name.should eq CameraFile::PREVIEW_FILENAME
        end
      end

      it "keeps the existing file when the download fails" do
        with_directory_camera do |camera, dir|
          target = File.join(dir, "out", "copy.jpg")
          Dir.mkdir_p(File.dirname(target))
          File.write(target, "previous")

          expect_raises(GPhoto2::Error) do
            camera.blob("/DCIM/missing.jpg").save(target)
          end
          File.read(target).should eq "previous"
        end
      end

      it "does not create directories when the download fails" do
        with_directory_camera do |camera, dir|
          expect_raises(GPhoto2::Error) do
            camera.blob("/DCIM/missing.jpg").save(File.join(dir, "new", "copy.jpg"))
          end
          Dir.exists?(File.join(dir, "new")).should be_false
        end
      end

      it "saves file data to the given path" do
        with_directory_camera do |camera, dir|
          target = File.join(dir, "out", "copy.jpg")
          camera.blob("/DCIM/a.jpg").save(target)
          File.read(target).should eq "hello"
        end
      end

      it "saves file data under its name inside the given directory" do
        with_directory_camera do |camera, dir|
          target = File.join(dir, "DCIM", "sub")
          camera.blob("/DCIM/a.jpg").save(target)
          File.read(File.join(target, "a.jpg")).should eq "hello"
        end
      end

      it "saves file data under its name inside a new directory given with a trailing separator" do
        with_directory_camera do |camera, dir|
          target = File.join(dir, "out", "new")
          camera.blob("/DCIM/a.jpg").save(target + File::SEPARATOR)
          File.read(File.join(target, "a.jpg")).should eq "hello"
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
