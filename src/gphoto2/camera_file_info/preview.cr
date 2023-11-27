require "./base"

module GPhoto2
  class CameraFileInfo
    class Preview < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoPreview)

      def width : UInt32?
        wrapped.width.to_u32 if field?(:width)
      end

      def height : UInt32?
        wrapped.height.to_u32 if field?(:height)
      end
    end
  end
end
