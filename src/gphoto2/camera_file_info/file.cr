require "./base"

module GPhoto2
  class CameraFileInfo
    class File < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoFile)

      def readable?
        has_field?(:permissions) && wrapped.permissions.read?
      end

      def deletable?
        has_field?(:permissions) && wrapped.permissions.delete?
      end

      def mtime : Time?
        Time.epoch(wrapped.mtime) if has_field?(:mtime)
      end

      def width : LibC::UInt32T?
        wrapped.width if has_field?(:width)
      end

      def height : LibC::UInt32T?
        wrapped.height if has_field?(:height)
      end
    end
  end
end
