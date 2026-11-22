module GPhoto2
  # Represents a camera event.
  struct CameraEvent(T)
    alias Type = LibGPhoto2::CameraEventType

    # Returns type of the event.
    getter type : Type

    # Returns data of the event, depending on its `#type`:
    #
    # - `CameraFile` for `Type::FileAdded` and `Type::FileChanged`
    # - `CameraFolder` for `Type::FolderAdded`
    # - `String` for `Type::Unknown`
    # - `nil` otherwise, or when the camera driver didn't pass any data
    getter data : T

    def initialize(@type : Type, @data)
    end
  end
end
