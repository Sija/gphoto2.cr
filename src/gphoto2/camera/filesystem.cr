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
      def filesystem(path : String = "/") : CameraFolder
        path = "/#{path}" unless path.starts_with? '/'
        CameraFolder.new(self, path)
      end

      # :ditto:
      def /(path) : CameraFolder
        filesystem(path)
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
