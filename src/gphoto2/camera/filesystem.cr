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
        path =
          path.is_a?(String) ? Path.posix(path) : path.to_posix

        path = Path.posix("/", path) unless path.absolute?

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
        path =
          path.is_a?(String) ? Path.posix(path) : path.to_posix

        path = Path.posix("/", path) unless path.absolute?

        fs = self / path.dirname
        fs.open(path.basename)
      end

      # Clear the filesystem.
      #
      # Resets the filesystem. All cached information including the folder tree
      # will get lost and will be queried again on demand.
      def filesystem_reset : Nil
        context.check! \
          LibGPhoto2.gp_filesystem_reset(wrapped.fs)
      end
    end
  end
end
