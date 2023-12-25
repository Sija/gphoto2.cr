module GPhoto2
  # Represents a camera event.
  struct CameraEvent(T)
    alias Type = LibGPhoto2::CameraEventType

    getter type : Type
    getter data : T

    def initialize(@type : Type, @data)
    end
  end
end
