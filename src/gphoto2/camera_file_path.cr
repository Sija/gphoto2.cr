module GPhoto2
  class CameraFilePath
    include GPhoto2::Struct(LibGPhoto2::CameraFilePath)

    def name : String
      String.new wrapped.name.to_unsafe
    end

    def folder : String
      String.new wrapped.folder.to_unsafe
    end

    def_equals name, folder
  end
end
