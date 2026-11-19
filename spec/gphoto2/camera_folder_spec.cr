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
    end

    describe "#put" do
      it "uploads a file" do
        with_directory_camera do |camera, dir|
          file = (camera / "DCIM").put("c.jpg", "data".to_slice)
          file.path.should eq Path.posix("/DCIM/c.jpg")
          File.read(File.join(dir, "DCIM", "c.jpg")).should eq "data"
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
          expect_raises(::Exception, "Cannot delete root folder") do
            (camera / "/").delete
          end
        end
      end
    end

    describe "#to_zip_file" do
      it "compresses folder contents" do
        with_directory_camera do |camera|
          zip_entries(camera / "DCIM").should eq({
            "DCIM/a.jpg"     => "hello",
            "DCIM/sub/b.jpg" => "xyz",
          })
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
