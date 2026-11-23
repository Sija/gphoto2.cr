require "./camera_folder/*"

module GPhoto2
  class CameraFolder
    include Compression

    # Returns folder path.
    getter path : Path

    protected getter camera : Camera
    protected delegate :context,
      to: @camera

    # Relative *path* is resolved from the root folder.
    def initialize(@camera, path : Path | String = "/")
      @path = GPhoto2.absolute_path(path)
    end

    def_equals_and_hash @camera, @path

    # Returns folder `#path` as string.
    def to_s(io : IO) : Nil
      io << @path
    end

    # Returns the folder `#path`, i.e. `#<GPhoto2::CameraFolder path="/DCIM">`.
    def inspect(io : IO) : Nil
      io << "#<" << self.class.name << " path=" << @path.to_s.inspect << '>'
    end

    # :ditto:
    def pretty_print(pp) : Nil
      pp.text inspect
    end

    # Returns `true` if folder `#path` is `/`.
    def root?
      # `Path#to_s` returns the underlying string, unlike `#to_s`, which builds one
      @path.to_s == "/"
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
    #
    # *name* can contain multiple path segments, including `.` and `..`,
    # while absolute *name* is resolved from the root folder.
    #
    # ```
    # folder = camera / "DCIM"
    # folder.cd("..").path       # => Path["/"]
    # folder.cd("sub/../x").path # => Path["/DCIM/x"]
    # folder.cd("/x").path       # => Path["/x"]
    # ```
    def cd(name : Path | String) : CameraFolder
      self.class.new(@camera, resolve(name))
    end

    # See: `#cd`
    def /(name : Path | String) : CameraFolder
      cd(name)
    end

    # Creates a new folder and returns it
    #
    # Raises `ArgumentError` if *name* is not a valid folder name
    # (i.e. it's empty, `.`, `..` or contains a `/`).
    def mkdir(name : String) : CameraFolder
      validate_name!(name)
      folder_make_dir(name)
      cd(name)
    end

    # Returns file by *name*, relative to current `#path`.
    #
    # See `#cd` for the supported *name* formats.
    #
    # Raises `ArgumentError` if *name* points to a folder, rather than
    # a file (i.e. it's empty, ends with `/`, `.` or `..`).
    def open(name : Path | String) : CameraFile
      if GPhoto2.folder_path?(name)
        raise ArgumentError.new("Invalid file name: #{name.to_s.inspect}")
      end
      CameraFile.new(@camera, resolve(name))
    end

    # :ditto:
    #
    # Yields the file and closes it upon return, returning the value of the block.
    def open(name : Path | String, &)
      file = open(name)
      begin
        yield file
      ensure
        # free the file data right away, instead of waiting for the GC
        file.close
      end
    end

    # Uploads a new file and returns it
    #
    # Raises `ArgumentError` if *name* is not a valid file name
    # (i.e. it's empty, `.`, `..` or contains a `/`).
    def put(name : String, data : Bytes, type : CameraFile::Type = :normal, *, mime_type : String? = nil, mtime : Time? = nil) : CameraFile
      validate_name!(name)

      # initialize the file with the data
      open(name) do |file|
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
      # ameba:disable Style/RedundantSelf
      self.folder_delete_all if files
      self.folders.each &.delete if folders
    end

    # Deletes this folder (along with all files and subfolders) from the camera.
    def delete : Nil
      raise GPhoto2::Exception.new("Cannot delete root folder") if root?
      # delete files and subfolders
      clear files: true, folders: true
      # finally, delete itself
      folder_remove_dir
    end

    # Names are passed to the camera as-is, while the returned objects
    # have their paths resolved (see `#resolve`), so the two must agree.
    private def validate_name!(name : String) : Nil
      if name.empty? || name.in?(".", "..") || name.includes?('/')
        raise ArgumentError.new("Invalid name: #{name.inspect}")
      end
    end

    # Absolute *name* is resolved from the root folder, as in a shell.
    private def resolve(name : Path | String) : Path
      # Converted the same way as by `GPhoto2.absolute_path`
      path = name.is_a?(String) ? Path.posix(name) : name.to_posix
      path = @path / path unless path.absolute?
      path.normalize
    end

    private def folder_list_files
      list = CameraList.new
      begin
        context.check! \
          LibGPhoto2.gp_camera_folder_list_files(@camera, @path.to_s, list, context)
        list.map { |file| open file.name }
      ensure
        list.close
      end
    end

    private def folder_list_folders
      list = CameraList.new
      begin
        context.check! \
          LibGPhoto2.gp_camera_folder_list_folders(@camera, @path.to_s, list, context)
        list.map { |folder| cd folder.name }
      ensure
        list.close
      end
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
        LibGPhoto2.gp_camera_folder_make_dir(@camera, @path.to_s, name.check_no_null_byte, context)
    end

    private def folder_put_file(file, name, type)
      context.check! \
        LibGPhoto2.gp_camera_folder_put_file(@camera, @path.to_s, name.check_no_null_byte, type, file, context)
    end
  end
end
