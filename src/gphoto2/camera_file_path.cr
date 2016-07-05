module GPhoto2
  class CameraFilePath
    include GPhoto2::Struct(FFI::LibGPhoto2::CameraFilePath)

    def name
      String.new wrapped.name.to_unsafe
    end

    def folder
      String.new wrapped.folder.to_unsafe
    end

    def_equals name, folder
  end
end
