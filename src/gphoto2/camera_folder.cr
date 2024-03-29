require "./camera_folder/*"

module GPhoto2
  class CameraFolder
    include Compression

    # Returns folder path.
    getter path : String

    protected getter camera : Camera
    protected delegate :context,
      to: @camera

    def initialize(@camera, @path = "/")
    end

    def_equals @camera, @path

    # Returns folder `#path`.
    def to_s
      path
    end

    # Returns `true` if folder `#path` is `/`.
    def root?
      path == "/"
    end

    # Returns folder name.
    def name : String
      File.basename(path)
    end

    # Lists sub-folders.
    def folders : Array(self)
      folder_list_folders
    end

    # Lists files.
    def files : Array(CameraFile)
      folder_list_files
    end

    # Returns subfolder by *name*, relative to current `#path`.
    def cd(name : String) : self
      case name
      when ".." then parent
      when "."  then self
      else
        self.class.new(@camera, CameraFile.join(@path, name))
      end
    end

    # See: `#cd`
    def /(name : String) : self
      cd(name)
    end

    # Returns file by *name*, relative to current `#path`.
    def open(name : String) : CameraFile
      CameraFile.new(@camera, @path, name)
    end

    # Returns parent folder or `nil`.
    def parent? : self?
      self.class.new(@camera, parent_path) unless root?
    end

    # Returns parent folder or `self`.
    def parent : self
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

    private def parent_path
      parent = @path[0...(@path.rindex('/') || 0)]
      parent = "/" if parent.empty?
      parent
    end

    private def folder_list_files
      list = CameraList.new
      context.check! \
        LibGPhoto2.gp_camera_folder_list_files(@camera, @path, list, context)
      list.to_a.map { |file| open file.name }
    end

    private def folder_list_folders
      list = CameraList.new
      context.check! \
        LibGPhoto2.gp_camera_folder_list_folders(@camera, @path, list, context)
      list.to_a.map { |folder| cd folder.name }
    end

    private def folder_delete_all
      context.check! \
        LibGPhoto2.gp_camera_folder_delete_all(@camera, @path, context)
    end

    private def folder_remove_dir
      context.check! \
        LibGPhoto2.gp_camera_folder_remove_dir(@camera, parent_path, name, context)
    end
  end
end
