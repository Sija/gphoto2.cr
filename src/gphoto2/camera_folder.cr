module GPhoto2
  class CameraFolder
    # Returns folder path.
    getter path : String

    protected delegate :context, to: @camera

    def initialize(@camera : Camera, @path : String = "/"); end

    # Returns `true` if folder `#path` is */*.
    def root?
      @path == "/"
    end

    # Returns folder name.
    def name : String
      return "/" if root?
      @path.split('/').last
    end

    # Lists folders.
    def folders : Array(self)
      folder_list_folders
    end

    # Lists files.
    def files : Array(CameraFile)
      folder_list_files
    end

    # Returns `CameraFolder` by *name*, relative to current `#path`.
    def cd(name : String) : self
      case name
      when ".."
        up
      when "."
        self
      else
        self.class.new(@camera, File.join(@path, name))
      end
    end

    # See: `#cd`
    def /(name : String) : self
      cd(name)
    end

    # Returns `CameraFile` by *name*, relative to current `#path`.
    def open(name : String) : CameraFile
      CameraFile.new(@camera, @path, name)
    end

    # Returns parent `CameraFolder`.
    def up : self
      if root?
        self # NOTE: would `nil` be more apt here?
      else
        parent = @path[0...(@path.rindex('/') || 0)]
        parent = "/" if parent.empty?
        self.class.new(@camera, parent)
      end
    end

    # Deletes all files.
    def clear : Void
      folder_delete_all
    end

    def to_s(io)
      io << name
    end

    def_equals @camera, @path

    private def folder_list_files
      list = CameraList.new
      context.check! LibGPhoto2.gp_camera_folder_list_files(@camera, @path, list, context)
      list.to_a.map { |f| open f.name }
    end

    private def folder_list_folders
      list = CameraList.new
      context.check! LibGPhoto2.gp_camera_folder_list_folders(@camera, @path, list, context)
      list.to_a.map { |f| cd f.name }
    end

    private def folder_delete_all
      context.check! LibGPhoto2.gp_camera_folder_delete_all(@camera, @path, context)
    end
  end
end
