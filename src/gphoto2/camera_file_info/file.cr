require "./base"

module GPhoto2
  class CameraFileInfo
    # Represents file information.
    class File < Base
      include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoFile)

      # Returns `true` if the file is readable, `false` otherwise,
      # or `nil` if the permissions are not reported.
      def readable? : Bool?
        wrapped.permissions.read? if field?(:permissions)
      end

      # Returns `true` if the file is removable, `false` otherwise,
      # or `nil` if the permissions are not reported.
      def removable? : Bool?
        wrapped.permissions.delete? if field?(:permissions)
      end

      # Returns modification time, or `nil` if it's not set
      # (or out of the range supported by `Time`).
      def mtime : Time?
        GPhoto2.time_from(wrapped.mtime) if field?(:mtime)
      end

      # Returns the width in pixels, or `nil` if it's not set
      # (or out of the `Int32` range, since cameras might report bogus values).
      def width : Int32?
        width = wrapped.width
        width.to_i32 if field?(:width) && width <= Int32::MAX
      end

      # Returns the height in pixels, or `nil` if it's not set
      # (or out of the `Int32` range, since cameras might report bogus values).
      def height : Int32?
        height = wrapped.height
        height.to_i32 if field?(:height) && height <= Int32::MAX
      end
    end
  end
end
