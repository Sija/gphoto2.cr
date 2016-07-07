module GPhoto2
  class Camera
    module Filesystem
      # @example
      #   # Get a list of filenames in a path.
      #   folder = camera/"store_00010001/DCIM/100D5100"
      #   folder.files.map(&.name)
      #   # => ["DSC_0001.JPG", "DSC_0002.JPG", ...]
      #
      def filesystem(root : String = "/")
        root = "/#{root}" unless root.starts_with? '/'
        CameraFolder.new(self, root)
      end

      def /(root)
        filesystem(root)
      end

      def file(file : CameraFile) : CameraFile
        file_get(file)
      end

      def delete(file : CameraFile) : Void
        file_delete(file)
      end

      private def file_get(file, type = LibGPhoto2::CameraFileType::Normal)
        GPhoto2.check! LibGPhoto2.gp_camera_file_get(self,
          file.folder.not_nil!, file.name.not_nil!,
          type, file, context)
        file
      end

      private def file_delete(file)
        GPhoto2.check! LibGPhoto2.gp_camera_file_delete(self,
          file.folder.not_nil!, file.name.not_nil!,
          context)
      end
    end
  end
end
