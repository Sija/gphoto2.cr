require "../spec_helper"

module GPhoto2
  private def self.zip_entries(folder, root = nil)
    entries = {} of String => String
    folder.to_zip_file(root) do |file|
      Compress::Zip::File.open(file.path) do |zip|
        zip.entries.each do |entry|
          entries[entry.filename] = entry.open(&.gets_to_end)
        end
      end
    end
    entries
  end

  describe CameraFolder do
    it "lists files" do
      with_directory_camera do |camera|
        (camera / "DCIM").files.map(&.name).should eq ["a.jpg"]
      end
    end

    it "lists folders" do
      with_directory_camera do |camera|
        (camera / "DCIM").folders.map(&.path)
          .should eq [Path.posix("/DCIM/sub")]
      end
    end

    it "makes relative paths absolute and normalizes them" do
      with_directory_camera do |camera|
        folder = CameraFolder.new(camera, "DCIM/sub/..")
        folder.path.should eq Path.posix("/DCIM")
        folder.should eq camera / "DCIM"
        folder.files.map(&.name).should eq ["a.jpg"]
      end
    end

    it "hashes by camera and path" do
      with_directory_camera do |camera|
        Set{camera / "DCIM", camera / "/DCIM"}.size.should eq 1
      end
    end

    describe "#root?" do
      it "returns true only for the root folder" do
        with_directory_camera do |camera|
          (camera / "/").root?.should be_true
          (camera / "DCIM").root?.should be_false
        end
      end
    end

    describe "#name" do
      it "returns the folder name" do
        with_directory_camera do |camera|
          (camera / "DCIM/sub").name.should eq "sub"
        end
      end
    end

    describe "#cd" do
      it "handles special names" do
        with_directory_camera do |camera|
          folder = camera / "DCIM"
          folder.cd(".").should eq folder
          folder.cd("..").root?.should be_true
          folder.cd("sub").path.should eq Path.posix("/DCIM/sub")
          (folder / "sub").path.should eq Path.posix("/DCIM/sub")
        end
      end

      it "normalizes compound names" do
        with_directory_camera do |camera|
          folder = camera / "DCIM"
          folder.cd("../x").path.should eq Path.posix("/x")
          folder.cd("sub/../x").path.should eq Path.posix("/DCIM/x")
          folder.cd("./sub/").path.should eq Path.posix("/DCIM/sub")
        end
      end

      it "resolves absolute names from the root folder" do
        with_directory_camera do |camera|
          folder = camera / "DCIM/sub"
          folder.cd("/").root?.should be_true
          folder.cd("/DCIM").path.should eq Path.posix("/DCIM")
          folder.cd("//DCIM/./sub/..").path.should eq Path.posix("/DCIM")
        end
      end

      it "does not go above the root folder" do
        with_directory_camera do |camera|
          (camera / "/").cd("..").root?.should be_true
          (camera / "DCIM").cd("../..").root?.should be_true
        end
      end
    end

    describe "#open" do
      it "returns a file by its relative path" do
        with_directory_camera do |camera|
          file = (camera / "DCIM/sub").open("../a.jpg")
          file.path.should eq Path.posix("/DCIM/a.jpg")
          String.new(file.to_slice).should eq "hello"
        end
      end

      it "returns a file by its absolute path" do
        with_directory_camera do |camera|
          file = (camera / "DCIM/sub").open("/DCIM/a.jpg")
          file.path.should eq Path.posix("/DCIM/a.jpg")
          String.new(file.to_slice).should eq "hello"
        end
      end

      it "raises for names pointing to a folder" do
        with_directory_camera do |camera|
          folder = camera / "DCIM/sub"
          {"", ".", "..", "sub/", "../..", "/", "x/."}.each do |name|
            expect_raises(ArgumentError, "Invalid file name: #{name.inspect}") do
              folder.open(name)
            end
          end
        end
      end

      it "yields the file and closes it after the block" do
        with_directory_camera do |camera|
          opened = nil
          data = (camera / "DCIM").open("a.jpg") do |file|
            opened = file
            file.path.should eq Path.posix("/DCIM/a.jpg")
            String.new(file.to_slice)
          end
          data.should eq "hello"
          opened.not_nil!.ptr?.should be_nil
        end
      end

      it "closes the file even when the block raises" do
        with_directory_camera do |camera|
          opened = nil
          expect_raises(::Exception, "oops") do
            (camera / "DCIM").open("a.jpg") do |file|
              opened = file
              file.size
              raise "oops"
            end
          end
          opened.not_nil!.ptr?.should be_nil
        end
      end
    end

    describe "#parent" do
      it "returns the parent folder" do
        with_directory_camera do |camera|
          (camera / "DCIM/sub").parent.path.should eq Path.posix("/DCIM")
        end
      end

      it "returns itself for the root folder" do
        with_directory_camera do |camera|
          root = camera / "/"
          root.parent?.should be_nil
          root.parent.should eq root
        end
      end
    end

    describe "#mkdir" do
      it "creates a folder" do
        with_directory_camera do |camera, dir|
          folder = (camera / "DCIM").mkdir("new")
          folder.path.should eq Path.posix("/DCIM/new")
          Dir.exists?(File.join(dir, "DCIM", "new")).should be_true
        end
      end

      it "rejects invalid names" do
        with_directory_camera do |camera|
          ["", ".", "..", "x/y"].each do |name|
            expect_raises(ArgumentError, "Invalid name") do
              (camera / "DCIM").mkdir(name)
            end
          end
        end
      end
    end

    describe "#put" do
      it "uploads a file" do
        with_directory_camera do |camera, dir|
          file = (camera / "DCIM").put("c.jpg", "data".to_slice)
          file.path.should eq Path.posix("/DCIM/c.jpg")
          File.read(File.join(dir, "DCIM", "c.jpg")).should eq "data"
        end
      end

      it "accepts mime type and modification time" do
        with_directory_camera do |camera, dir|
          (camera / "DCIM").put("c.jpg", "data".to_slice,
            mime_type: "image/jpeg", mtime: Time.unix(1_000_000))
          File.read(File.join(dir, "DCIM", "c.jpg")).should eq "data"
        end
      end

      it "returns a fresh file" do
        with_directory_camera do |camera|
          file = (camera / "DCIM").put("c.jpg", "data".to_slice)
          String.new(file.to_slice).should eq "data"
        end
      end

      it "rejects invalid names" do
        with_directory_camera do |camera, dir|
          ["", ".", "..", "sub/c.jpg"].each do |name|
            expect_raises(ArgumentError, "Invalid name") do
              (camera / "DCIM").put(name, "data".to_slice)
            end
          end
          File.exists?(File.join(dir, "DCIM", "sub", "c.jpg")).should be_false
        end
      end
    end

    describe "#clear" do
      it "deletes files only by default" do
        with_directory_camera do |camera, dir|
          (camera / "DCIM").clear
          File.exists?(File.join(dir, "DCIM", "a.jpg")).should be_false
          Dir.exists?(File.join(dir, "DCIM", "sub")).should be_true
        end
      end
    end

    describe "#delete" do
      it "deletes the folder recursively" do
        with_directory_camera do |camera, dir|
          (camera / "DCIM").delete
          Dir.exists?(File.join(dir, "DCIM")).should be_false
        end
      end

      it "refuses to delete the root folder" do
        with_directory_camera do |camera|
          expect_raises(GPhoto2::Exception, "Cannot delete root folder") do
            (camera / "/").delete
          end
        end
      end
    end

    describe "#to_zip_file" do
      it "clamps modification times to the range supported by the format" do
        with_directory_camera do |camera, dir|
          path = File.join(dir, "DCIM", "a.jpg")
          {Time.unix(86_400) => 1980, Time.utc(2110, 1, 1) => 2107}.each do |mtime, year|
            File.touch(path, mtime)
            camera.filesystem_reset

            (camera / "DCIM").to_zip_file do |file|
              Compress::Zip::File.open(file.path) do |zip|
                zip["DCIM/a.jpg"].time.year.should eq year
              end
            end
          end
        end
      end

      it "stores modification times as local time" do
        # Make sure the local time differs from UTC (i.e. on CI)
        local = Time::Location.local
        Time::Location.local = Time::Location.fixed(2 * 3600)
        begin
          with_directory_camera do |camera, dir|
            mtime = Time.local(2024, 6, 1, 12, 0, 0)
            File.touch(File.join(dir, "DCIM", "a.jpg"), mtime)

            (camera / "DCIM").to_zip_file do |file|
              Compress::Zip::File.open(file.path) do |zip|
                # MS-DOS timestamps are read back (as UTC) by `Compress::Zip`
                time = zip["DCIM/a.jpg"].time
                {time.year, time.month, time.day, time.hour, time.minute}
                  .should eq({2024, 6, 1, 12, 0})
              end
            end
          end
        ensure
          Time::Location.local = local
        end
      end

      it "doesn't download the files as a whole" do
        with_directory_camera do |camera|
          data = Bytes.new(CameraFile::CHUNK_SIZE * 2 + 123) { |i| (i % 251).to_u8 }
          stub = stub_file_read(camera, data, reported_size: data.size.to_u64, max_read_size: 1000_u64)

          entries = {} of String => Bytes
          (camera / "DCIM").to_zip_file do |file|
            Compress::Zip::File.open(file.path) do |zip|
              zip.entries.each do |entry|
                entries[entry.filename] = entry.open(&.getb_to_end)
              end
            end
          end
          entries["DCIM/a.jpg"].should eq data
          stub.downloads.should eq 0
        end
      end

      it "compresses folder contents" do
        with_directory_camera do |camera|
          zip_entries(camera / "DCIM").should eq({
            "DCIM/a.jpg"     => "hello",
            "DCIM/sub/b.jpg" => "xyz",
          })
        end
      end

      it "keeps empty folders" do
        with_directory_camera do |camera, dir|
          Dir.mkdir_p(File.join(dir, "DCIM", "sub", "empty"))
          zip_entries(camera / "DCIM").should eq({
            "DCIM/a.jpg"      => "hello",
            "DCIM/sub/b.jpg"  => "xyz",
            "DCIM/sub/empty/" => "",
          })
        end
      end

      it "returns an empty archive for an empty root folder" do
        with_fixture_dir do |dir|
          FileUtils.rm_rf(File.join(dir, "DCIM"))
          camera = Camera.new(DIRECTORY_CAMERA_MODEL, "disk:#{dir}")
          begin
            zip_entries(camera / "/").should be_empty
          ensure
            camera.close
          end
        end
      end

      it "keeps the compressed folder itself when empty" do
        with_directory_camera do |camera, dir|
          Dir.mkdir_p(File.join(dir, "DCIM", "sub", "empty"))
          zip_entries(camera / "DCIM/sub/empty").should eq({"empty/" => ""})
        end
      end

      it "uses the given root folder name" do
        with_directory_camera do |camera|
          zip_entries(camera / "DCIM", "photos").should eq({
            "photos/a.jpg"     => "hello",
            "photos/sub/b.jpg" => "xyz",
          })
        end
      end

      it "returns the value of the block" do
        with_directory_camera do |camera|
          (camera / "DCIM").to_zip_file { |file| File.size(file.path) }.should be > 0
        end
      end

      it "refuses entry names pointing outside of the archive" do
        with_directory_camera do |camera|
          ["../evil", "..\\evil", "C:/evil", "c:evil"].each do |root|
            expect_raises(ArgumentError, "Invalid entry name") do
              (camera / "DCIM").to_zip_file(root) { }
            end
          end
          # Plain names are fine
          (camera / "DCIM").to_zip_file("photos") { }
        end
      end

      it "removes the temporary file on failure" do
        with_directory_camera do |camera, dir|
          tempfiles = -> { Dir.glob(File.join(Dir.tempdir, "camera.fs-*.zip")) }
          existing = tempfiles.call

          # Remove the (already listed) file, so that the compression
          # fails midway (regardless of the process privileges)
          (camera / "DCIM").files
          File.delete(File.join(dir, "DCIM", "a.jpg"))

          expect_raises(GPhoto2::Error) do
            (camera / "DCIM").to_zip_file { }
          end
          (tempfiles.call - existing).should be_empty
        end
      end

      it "compresses the root folder" do
        with_directory_camera do |camera|
          zip_entries(camera / "/").should eq({
            "DCIM/a.jpg"     => "hello",
            "DCIM/sub/b.jpg" => "xyz",
          })
        end
      end
    end

    describe "#to_s" do
      it "returns the folder path" do
        with_directory_camera do |camera|
          folder = camera / "DCIM"
          folder.to_s.should eq "/DCIM"
          "#{folder}".should eq "/DCIM"
        end
      end
    end
  end
end
