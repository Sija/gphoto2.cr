module GPhoto2
  alias CameraEventType = LibGPhoto2::CameraEventType

  record CameraEvent(T),
    type : CameraEventType,
    data : T
end
