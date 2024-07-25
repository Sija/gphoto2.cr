require "./base"

module GPhoto2
  class CameraFileInfo
    # Represents preview information.
    class Preview < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoPreview)

      # Returns the width of the preview.
      def width : Int32?
        wrapped.width.to_i32 if field?(:width)
      end

      # Returns the height of the preview.
      def height : Int32?
        wrapped.height.to_i32 if field?(:height)
      end
    end
  end
end
