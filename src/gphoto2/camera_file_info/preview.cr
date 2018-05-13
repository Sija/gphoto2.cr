require "./base"

module GPhoto2
  class CameraFileInfo
    class Preview < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoPreview)

      def width : LibC::UInt32T?
        wrapped.width if field?(:width)
      end

      def height : LibC::UInt32T?
        wrapped.height if field?(:height)
      end
    end
  end
end
