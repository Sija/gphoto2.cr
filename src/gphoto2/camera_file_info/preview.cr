require "./base"

module GPhoto2
  class CameraFileInfo
    # Represents preview information.
    class Preview < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoPreview)

      # Returns the width of the preview, or `nil` if it's not set
      # (or out of the `Int32` range, since cameras might report bogus values).
      def width : Int32?
        width = wrapped.width
        width.to_i32 if field?(:width) && width <= Int32::MAX
      end

      # Returns the height of the preview, or `nil` if it's not set
      # (or out of the `Int32` range, since cameras might report bogus values).
      def height : Int32?
        height = wrapped.height
        height.to_i32 if field?(:height) && height <= Int32::MAX
      end
    end
  end
end
