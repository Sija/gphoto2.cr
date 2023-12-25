module GPhoto2
  # Represents a path representing a file or folder.
  class CameraFilePath
    include GPhoto2::Struct(LibGPhoto2::CameraFilePath)

    # Returns the name part of the path.
    def name : String
      String.new wrapped.name.to_unsafe
    end

    # Returns the folder part of the path.
    def folder : String
      String.new wrapped.folder.to_unsafe
    end

    def_equals name, folder
  end
end
