module GPhoto2
  # Represents a path representing a file or folder.
  struct CameraFilePath
    # Returns the name part of the path.
    getter name : String

    # Returns the folder part of the path.
    getter folder : String

    def initialize(path : LibGPhoto2::CameraFilePath)
      @name = String.new(path.name.to_unsafe)
      @folder = String.new(path.folder.to_unsafe)
    end

    def_equals name, folder
  end
end
