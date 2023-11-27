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

      def width : UInt32?
        wrapped.width.to_u32 if field?(:width)
      end

      def height : UInt32?
        wrapped.height.to_u32 if field?(:height)
      end
    end
  end
end
