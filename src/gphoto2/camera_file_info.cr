require "./struct"

module GPhoto2
  abstract class CameraFileInfo
    # include GPhoto2::Struct(LibGPhoto2::CameraFileInfo)

    def fields
      wrapped.fields
    end

    def has_field?(field : Symbol | String)
      fields.includes? LibGPhoto2::CameraFileInfoFields.parse(field.to_s)
    end

    def status : LibGPhoto2::CameraFileStatus
      wrapped.status
    end

    def size : UInt64
      wrapped.size
    end

    def type : String?
      if wrapped.type.size > 0
        String.new wrapped.type.to_unsafe
      end
    end
  end

  class CameraFileInfoFile < CameraFileInfo
    include GPhoto2::Struct(LibGPhoto2::CameraFileInfoFile)

    def readable? : Bool
      wrapped.permissions.read?
    end

    def deletable? : Bool
      wrapped.permissions.delete?
    end

    def mtime : Time
      Time.epoch(wrapped.mtime)
    end

    def width : UInt32?
      wrapped.width if wrapped.width > 0
    end

    def height : UInt32?
      wrapped.height if wrapped.height > 0
    end
  end
end
