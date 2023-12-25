require "./base"

module GPhoto2
  class CameraFileInfo
    # Represents file information.
    class File < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoFile)

      # Returns `true` if the file is readable, `false` otherwise.
      def readable?
        field?(:permissions) && wrapped.permissions.read?
      end

      # Returns `true` if the file is removable, `false` otherwise.
      def removable?
        field?(:permissions) && wrapped.permissions.delete?
      end

      # Returns modification time.
      def mtime : Time?
        Time.unix(wrapped.mtime) if field?(:mtime)
      end

      # Returns the width in pixels.
      def width : UInt32?
        wrapped.width.to_u32 if field?(:width)
      end

      # Returns the height in pixels.
      def height : UInt32?
        wrapped.height.to_u32 if field?(:height)
      end
    end
  end
end
