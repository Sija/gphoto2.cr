module GPhoto2
  class CameraFolder
    @path : String
    getter :path

    def initialize(@camera : Camera, @path = "/"); end

    def root?
      @path == "/"
    end

    def name
      return "/" if root?
      @path.split("/").last
    end

    def folders : Array(self)
      folder_list_folders
    end

    def files : Array(CameraFile)
      folder_list_files
    end

    def cd(name : String) : self
      case name
      when "."
        self
      when ".."
        up
      else
        CameraFolder.new(@camera, File.join(@path, name))
      end
    end

    def /(name : String)
      cd(name)
    end

    def open(name : String)
      CameraFile.new(@camera, @path, name)
    end

    def up
      if root?
        self
      else
        parent = @path[0...(@path.rindex("/") || 0)]
        parent = "/" if parent.empty?
        CameraFolder.new(@camera, parent)
      end
    end

    def to_s(io)
      io << name
    end

    def_equals @camera, @path

    private def folder_list_files : Array(CameraFile)
      list = CameraList.new
      GPhoto2.check! LibGPhoto2.gp_camera_folder_list_files(@camera, @path, list, @camera.context)
      list.to_a.map { |f| open f.name.not_nil! }
    end

    private def folder_list_folders : Array(self)
      list = CameraList.new
      GPhoto2.check! LibGPhoto2.gp_camera_folder_list_folders(@camera, @path, list, @camera.context)
      list.to_a.map { |f| cd f.name.not_nil! }
    end
  end
end
