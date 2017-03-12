require "./struct"

module GPhoto2
  class CameraFile
    include GPhoto2::Struct(LibGPhoto2::CameraFile)

    # The preview data is assumed to be a jpg.
    PREVIEW_FILENAME = "capture_preview.jpg"

    # Initial buffer size used in `#read`.
    BUFFER_SIZE = 256 * 1024

    getter! folder : String
    getter! name : String

    protected getter camera : Camera
    protected delegate :context, to: @camera

    # Returns a new string formed by joining the strings using `/`.
    #
    # NOTE: OS-independent substitute of `File.join` applicable to *libgphoto2* fs.
    def self.join(*args : String) : String
      args.join '/', &.chomp('/')
    end

    def initialize(@camera : Camera, @folder : String? = nil, @name : String? = nil)
      new
    end

    def finalize
      close
    end

    def close : Void
      free if ptr?
    end

    # Returns `true` if file is a preview.
    def preview?
      !(@folder && @name)
    end

    # Saves file `#data` at given *pathname*.
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

    # Returns file size (in bytes).
    def size : LibC::ULong
      data_and_size.last
    end

    # Returns file `#data` as `Bytes`.
    def to_slice : Bytes
      data.to_slice(size)
    end

    # Reads file directly from the camera.
    def read : Bytes
      _read
    end

    # Returns `CameraFileInfo` object containing information about the file.
    def info : CameraFileInfo
      get_info
    end

    # Returns file extension in lowercase (without leading dot).
    def extension : String
      File.extname(name).split('.').last.downcase
    end

    # Returns full file path (within the camera filesystem).
    def path : String
      self.class.join folder, name
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

    private getter data_and_size : {UInt8*, LibC::ULong} do
      get unless preview?
      get_data_and_size
    end

    private def get_data_and_size
      GPhoto2.check! LibGPhoto2.gp_file_get_data_and_size(self, out data, out size)
      {data, size}
    end

    private def get(type = LibGPhoto2::CameraFileType::Normal)
      context.check! LibGPhoto2.gp_camera_file_get(@camera, folder, name, type, self, context)
    end

    private def _read(buffer, offset, type)
      size = buffer.size.to_u64

      context.check! LibGPhoto2.gp_camera_file_read(@camera, folder, name, type,
        offset, buffer, pointerof(size), context)

      offset += size
      {offset, size}
    end

    private def _read(type = LibGPhoto2::CameraFileType::Normal)
      buffer = Bytes.new(BUFFER_SIZE)
      offset, size = _read(buffer, 0_u64, type)

      data = Pointer(UInt8).malloc(size)
      data.copy_from(buffer.to_unsafe, size)

      while size == buffer.size
        offset, size = _read(buffer, offset, type)
        data = data.realloc(offset)
        data_with_offset = data + (offset - size)
        data_with_offset.copy_from(buffer.to_unsafe, size)
      end
      data.to_slice(offset)
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
