module GPhoto2
  record CameraEvent(T),
    type : LibGPhoto2::CameraEventType,
    data : T
end
