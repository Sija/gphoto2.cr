require "./struct"

module GPhoto2
  class CameraFileInfoPreview < CameraFileInfo
    include GPhoto2::ManagedStruct(LibGPhoto2::CameraFileInfoPreview)

    def width : LibC::UInt32T?
      wrapped.width if has_field?(:width)
    end

    def height : LibC::UInt32T?
      wrapped.height if has_field?(:height)
    end
  end
end