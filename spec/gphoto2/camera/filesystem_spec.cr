require "../../spec_helper"

module GPhoto2
  # Makes *camera* report the storages built by *func*,
  # or not support storage info at all, when not given.
  private def self.stub_storage_info(camera : Camera, func : LibGPhoto2::CameraFilesystemStorageInfoFunc? = nil) : Nil
    # Make sure the driver is initialized, so it doesn't override our functions
    camera.filesystem.files

    funcs = LibGPhoto2::CameraFilesystemFuncs.new
    funcs.storage_info_func = func if func
    GPhoto2.check! \
      LibGPhoto2.gp_filesystem_set_funcs(camera.wrapped.fs, pointerof(funcs), nil)
  end

  # Returns *string* as a null-terminated, fixed-size C chars array.
  private def self.chars(string : String) : StaticArray(LibC::Char, 256)
    chars = StaticArray(LibC::Char, 256).new(0_u8)
    chars.to_unsafe.copy_from(string.to_unsafe, string.bytesize)
    chars
  end

  describe Camera::Filesystem do
    describe "#storage_info" do
      it "returns information about the storages" do
        with_directory_camera do |camera|
          storages = camera.storage_info
          storages.size.should eq 1

          storage = storages.first
          storage.base_dir.should eq "/"
          storage.description.should eq "Directory Driver"
          storage.access.should eq CameraStorageInfo::AccessType::ReadWrite
          storage.writable?.should be_true
          storage.filesystem_type.should eq CameraStorageInfo::FilesystemType::GenericHierarchical
          storage.capacity_kbytes.should_not be_nil
        end
      end

      it "returns nil for the values not reported" do
        with_directory_camera do |camera|
          storage = camera.storage_info.first
          storage.fields.label?.should be_false
          storage.label.should be_nil
          storage.free_images.should be_nil
        end
      end

      it "returns all of the storages, with all of their values" do
        with_directory_camera do |camera|
          stub_storage_info camera, ->(_fs : LibGPhoto2::CameraFilesystem*, infos : LibGPhoto2::CameraStorageInformation**, count : LibC::Int*, _data : Void*, _context : LibGPhoto2::GPContext*) {
            # Freed by the caller
            array = LibC.malloc(2 * sizeof(LibGPhoto2::CameraStorageInformation))
              .as(LibGPhoto2::CameraStorageInformation*)

            {"/store_00010001", "/store_00020001"}.each_with_index do |base_dir, i|
              info = LibGPhoto2::CameraStorageInformation.new
              info.fields = LibGPhoto2::CameraStorageInfoFields::All
              info.basedir = chars(base_dir)
              info.label = chars("CARD")
              info.type = LibGPhoto2::CameraStorageType::RemovableRam
              info.fstype = LibGPhoto2::CameraStorageFilesystemType::Dcf
              info.access = LibGPhoto2::CameraStorageAccessType::ReadOnly
              info.capacitykbytes = 1000_u64 * (i + 1)
              info.freekbytes = 500_u64
              info.freeimages = 42_u64
              array[i] = info
            end

            infos.value = array
            count.value = 2
            LibGPhoto2::GP_OK
          }

          storages = camera.storage_info
          storages.map(&.base_dir).should eq ["/store_00010001", "/store_00020001"]
          storages.map(&.capacity_kbytes).should eq [1000, 2000]

          storage = storages.first
          storage.label.should eq "CARD"
          storage.description.should eq ""
          storage.type.should eq CameraStorageInfo::Type::RemovableRam
          storage.filesystem_type.should eq CameraStorageInfo::FilesystemType::Dcf
          storage.access.should eq CameraStorageInfo::AccessType::ReadOnly
          storage.writable?.should be_false
          storage.free_kbytes.should eq 500
          storage.free_images.should eq 42
        end
      end

      it "returns no storages when the driver doesn't report any" do
        with_directory_camera do |camera|
          stub_storage_info camera, ->(_fs : LibGPhoto2::CameraFilesystem*, _infos : LibGPhoto2::CameraStorageInformation**, count : LibC::Int*, _data : Void*, _context : LibGPhoto2::GPContext*) {
            count.value = 0
            LibGPhoto2::GP_OK
          }
          camera.storage_info.should be_empty
        end
      end

      it "raises when the driver doesn't support it" do
        with_directory_camera do |camera|
          stub_storage_info camera
          error = expect_raises(GPhoto2::Error) do
            camera.storage_info
          end
          error.code.should eq LibGPhoto2::GP_ERROR_NOT_SUPPORTED
        end
      end
    end
  end
end
