module GPhoto2
  # Represents a path representing a file or folder.
  struct CameraFilePath
    # Returns the name part of the path.
    getter name : String

    # Returns the folder part of the path.
    getter folder : String

    def initialize(path : LibGPhoto2::CameraFilePath)
      @name = GPhoto2.string_from(path.name)
      @folder = GPhoto2.string_from(path.folder)
    end

    def_equals name, folder

    def to_path : Path
      Path.posix(folder) / name
    end
  end
end
