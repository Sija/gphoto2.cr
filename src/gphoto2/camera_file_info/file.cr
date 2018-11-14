require "./base"

module GPhoto2
  class CameraFileInfo
    class File < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoFile)

      def readable?
        field?(:permissions) && wrapped.permissions.read?
      end

      def deletable?
        field?(:permissions) && wrapped.permissions.delete?
      end

      def mtime : Time?
        Time.unix(wrapped.mtime) if field?(:mtime)
      end

      def width : LibC::UInt32T?
        wrapped.width if field?(:width)
      end

      def height : LibC::UInt32T?
        wrapped.height if field?(:height)
      end
    end
  end
end
