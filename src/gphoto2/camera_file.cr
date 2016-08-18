require "./struct"

module GPhoto2
  class CameraFile
    include GPhoto2::Struct(LibGPhoto2::CameraFile)

    # The preview data is assumed to be a jpg.
    PREVIEW_FILENAME = "capture_preview.jpg"

    @camera : Camera
    @data_and_size : {UInt8*, LibC::ULong}?

    getter! folder : String?
    getter! name : String?

    protected delegate :context, to: @camera

    def initialize(@camera : Camera, @folder : String? = nil, @name : String? = nil)
      new
    end

    def finalize
      close
    end

    def close : Void
      free
    end

    def preview?
      !(@folder && @name)
    end

    def save(pathname : String = default_filename) : Void
      unless Dir.exists? pathname
        Dir.mkdir_p File.dirname(pathname)
      end
      File.open pathname, "w", &.write(to_slice)
    end

    # Deletes file from the camera.
    def delete : Void
      _delete
    end

    # Returns file data.
    def data : UInt8*
      data_and_size.first
    end

    # Returns size of the file (in bytes).
    def size : LibC::ULong
      data_and_size.last
    end

    def to_slice : Bytes
      data.to_slice(size)
    end

    def info : CameraFileInfo?
      get_info unless preview?
    end

    # Returns file extension in lowercase (without leading dot).
    def extension : String
      File.extname(name).split('.').last.downcase
    end

    # Returns file mime type.
    def type : String?
      info.try &.file.type
    end

    # Returns full file path (within the camera filesystem).
    def path : String
      File.join folder, name
    end

    def_equals @camera, @folder, @name

    private def new
      GPhoto2.check! LibGPhoto2.gp_file_new(out ptr)
      self.ptr = ptr
    end

    private def free
      GPhoto2.check! LibGPhoto2.gp_file_free(self)
      self.ptr = nil
    end

    private def default_filename
      preview? ? PREVIEW_FILENAME : name
    end

    private def data_and_size
      @data_and_size ||= begin
        get unless preview?
        get_data_and_size
      end
    end

    private def get_data_and_size
      GPhoto2.check! LibGPhoto2.gp_file_get_data_and_size(self, out data, out size)
      {data, size}
    end

    private def get(type = LibGPhoto2::CameraFileType::Normal)
      context.check! LibGPhoto2.gp_camera_file_get(@camera, folder, name, type, self, context)
    end

    private def get_info
      context.check! LibGPhoto2.gp_camera_file_get_info(@camera, folder, name, out info, context)
      CameraFileInfo.new info
    end

    private def _delete
      context.check! LibGPhoto2.gp_camera_file_delete(@camera, folder, name, context)
    end
  end
end
