module GPhoto2
  class CameraFolder
    getter path : String

    def initialize(@camera : Camera, @path : String = "/"); end

    def root?
      @path == "/"
    end

    def name : String
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

    def /(name : String) : self
      cd(name)
    end

    def open(name : String) : CameraFile
      CameraFile.new(@camera, @path, name)
    end

    def up : self
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

    private def folder_list_files
      list = CameraList.new
      GPhoto2.check! LibGPhoto2.gp_camera_folder_list_files(@camera, @path, list, @camera.context)
      list.to_a.map { |f| open f.name }
    end

    private def folder_list_folders
      list = CameraList.new
      GPhoto2.check! LibGPhoto2.gp_camera_folder_list_folders(@camera, @path, list, @camera.context)
      list.to_a.map { |f| cd f.name }
    end
  end
end
