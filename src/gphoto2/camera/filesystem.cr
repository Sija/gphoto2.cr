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

      def /(root) : CameraFolder
        filesystem(root)
      end

      def file(file : CameraFile) : CameraFile
        file_get(file)
      end

      def delete(file : CameraFile) : Void
        file_delete(file)
      end

      private def file_get(file, type = LibGPhoto2::CameraFileType::Normal)
        context.check! LibGPhoto2.gp_camera_file_get(self, file.folder, file.name, type, file, context)
        file
      end

      private def file_delete(file)
        context.check! LibGPhoto2.gp_camera_file_delete(self, file.folder, file.name, context)
      end
    end
  end
end
