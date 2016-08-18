module GPhoto2
  class Camera
    module Filesystem
      # ```
      # # Get a list of filenames in a path.
      # folder = camera/"store_00010001/DCIM/100D5100"
      # folder.files.map(&.name) # => ["DSC_0001.JPG", "DSC_0002.JPG", ...]
      # ```
      def filesystem(root : String = "/") : CameraFolder
        root = "/#{root}" unless root.starts_with? '/'
        CameraFolder.new(self, root)
      end

      # :ditto:
      def /(root) : CameraFolder
        filesystem(root)
      end
    end
  end
end
