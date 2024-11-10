require "./camera_folder/*"

module GPhoto2
  class CameraFolder
    include Compression

    # Returns folder path.
    getter path : Path

    protected getter camera : Camera
    protected delegate :context,
      to: @camera

    def initialize(@camera, path : Path | String = "/")
      @path =
        path.is_a?(String) ? Path.posix(path) : path.to_posix
    end

    def_equals @camera, @path

    # Returns folder `#path` as string.
    def to_s
      @path.to_s
    end

    # Returns `true` if folder `#path` is `/`.
    def root?
      to_s == "/"
    end

    # Returns folder name.
    def name : String
      @path.basename
    end

    # Lists sub-folders.
    def folders : Array(CameraFolder)
      folder_list_folders
    end

    # Lists files.
    def files : Array(CameraFile)
      folder_list_files
    end

    # Returns subfolder by *name*, relative to current `#path`.
    def cd(name : String) : CameraFolder
      case name
      when ".." then parent
      when "."  then self
      else
        self.class.new(@camera, @path / name)
      end
    end

    # See: `#cd`
    def /(name : String) : CameraFolder
      cd(name)
    end

    # Creates a new folder and returns it
    def mkdir(name : String) : CameraFolder
      folder_make_dir(name)
      cd(name)
    end

    # Returns file by *name*, relative to current `#path`.
    def open(name : String) : CameraFile
      CameraFile.new(@camera, @path / name)
    end

    # Uploads a new file and returns it
    def put(name : String, data : Bytes, type : CameraFile::Type = :normal, *, mime_type : String? = nil, mtime : Time? = nil) : CameraFile
      # initialize the file with the data
      open(name).tap do |file|
        file.data = data
        file.mime_type = mime_type if mime_type
        file.mtime = mtime if mtime

        folder_put_file(file, name, type)
      end
      # reopen the file to get it "fresh" from the device
      open(name)
    end

    # Returns parent folder or `nil`.
    def parent? : CameraFolder?
      self.class.new(@camera, @path.parent) unless root?
    end

    # Returns parent folder or `self`.
    def parent : CameraFolder
      parent? || self
    end

    # Deletes all files and/or sub-folders.
    def clear(files : Bool = true, folders : Bool = false) : Nil
      self.folder_delete_all if files
      self.folders.each &.delete if folders
    end

    # Deletes this folder (along with all files and subfolders) from the camera.
    def delete : Nil
      raise "Cannot delete root folder" if root?
      # delete files and subfolders
      clear files: true, folders: true
      # finally, delete itself
      folder_remove_dir
    end

    private def folder_list_files
      list = CameraList.new
      context.check! \
        LibGPhoto2.gp_camera_folder_list_files(@camera, @path.to_s, list, context)
      list.to_a.map { |file| open file.name }
    end

    private def folder_list_folders
      list = CameraList.new
      context.check! \
        LibGPhoto2.gp_camera_folder_list_folders(@camera, @path.to_s, list, context)
      list.to_a.map { |folder| cd folder.name }
    end

    private def folder_delete_all
      context.check! \
        LibGPhoto2.gp_camera_folder_delete_all(@camera, @path.to_s, context)
    end

    private def folder_remove_dir
      context.check! \
        LibGPhoto2.gp_camera_folder_remove_dir(@camera, @path.parent.to_s, name, context)
    end

    private def folder_make_dir(name)
      context.check! \
        LibGPhoto2.gp_camera_folder_make_dir(@camera, @path.to_s, name, context)
    end

    private def folder_put_file(file, name, type)
      context.check! \
        LibGPhoto2.gp_camera_folder_put_file(@camera, @path.to_s, name, type, file, context)
    end
  end
end
