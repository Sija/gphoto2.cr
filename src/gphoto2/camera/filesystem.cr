module GPhoto2
  class Camera
    module Filesystem
      # Returns `CameraFolder` instance of the given *path*.
      #
      # ```
      # # Get a list of filenames in a path.
      # folder = camera/"store_00010001/DCIM/100D5100"
      # folder.files.map(&.name) # => ["DSC_0001.JPG", "DSC_0002.JPG", ...]
      # ```
      def filesystem(path : Path | String = "/") : CameraFolder
        CameraFolder.new(self, path)
      end

      # :ditto:
      def /(path) : CameraFolder
        filesystem(path)
      end

      # Returns `CameraFile` instance of the given *path*.
      #
      # ```
      # file = camera.blob("/store_00010001/DCIM/100D5100/DSC_0001.JPG")
      # file.name # => "DSC_0001.JPG"
      # ```
      def blob(path : Path | String) : CameraFile
        CameraFile.new(self, path)
      end

      # Returns information about the camera storages (i.e. memory cards).
      #
      # ```
      # camera.storage_info.each do |storage|
      #   puts "#{storage.base_dir}: #{storage.free_kbytes} KiB free"
      # end
      # ```
      #
      # Raises `GPhoto2::Error` if the camera driver doesn't support it.
      def storage_info : Array(CameraStorageInfo)
        # Null-initialized (unlike `out` variables), since drivers aren't
        # guaranteed to set them, which would leave these pointing to garbage
        infos = Pointer(LibGPhoto2::CameraStorageInformation).null
        count = 0
        rc = LibGPhoto2.gp_camera_get_storageinfo(self, pointerof(infos), pointerof(count), context)
        begin
          context.check!(rc)
          return [] of CameraStorageInfo if infos.null?

          Array(CameraStorageInfo).new(Math.max(count, 0)) do |i|
            CameraStorageInfo.new(infos[i])
          end
        ensure
          # The array is allocated by the camera driver and must be freed by
          # the caller, after a successful call (even when one of the callbacks raised)
          LibC.free(infos) if infos && GPhoto2.check?(rc)
        end
      end

      # Clear the filesystem.
      #
      # Resets the filesystem. All cached information including the folder tree
      # will get lost and will be queried again on demand.
      def filesystem_reset : Nil
        # Doesn't take the context, so there are no messages to check for
        GPhoto2.check! \
          LibGPhoto2.gp_filesystem_reset(wrapped.fs)
      end
    end
  end
end
