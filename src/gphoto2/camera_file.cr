require "./struct"

module GPhoto2
  class CameraFile
    include GPhoto2::Struct(LibGPhoto2::CameraFile)

    alias Type = LibGPhoto2::CameraFileType

    # The unknown mime type as specified by the libgphoto2.
    UNKNOWN_MIME_TYPE = "unknown/unknown"

    # The preview data is assumed to be a jpg.
    PREVIEW_FILENAME = "capture_preview.jpg"

    # Initial buffer size used in `#read`.
    BUFFER_SIZE = 256 * 1024

    # Returns file path.
    getter path : Path

    protected getter camera : Camera
    protected delegate :context,
      to: @camera

    # NOTE: allocates memory.
    def initialize(@camera, path : Path | String)
      @path =
        path.is_a?(String) ? Path.posix(path) : path.to_posix

      new
    end

    # :ditto:
    def initialize(@camera)
      initialize(@camera, PREVIEW_FILENAME)
    end

    def_equals_and_hash @camera, @path

    # Returns file `#path`.
    def to_s(io : IO) : Nil
      io << @path
    end

    def name
      @path.basename
    end

    def folder
      @path.dirname
    end

    # Finalizes object by freeing allocated memory.
    def finalize
      close
    end

    # NOTE: frees allocated memory.
    def close : Nil
      free if ptr?
    end

    # Returns `true` if file is a preview.
    def preview?
      to_s == PREVIEW_FILENAME
    end

    # Saves file `#data` at given *path*, defaulting to file `#name`
    # in the current working directory.
    def save(path : Path | String = name) : Nil
      path = Path[path] if path.is_a?(String)

      Dir.mkdir_p(path.dirname)
      File.write(path, to_slice)
    end

    # Deletes file from the camera.
    def delete : Nil
      _delete
    end

    # :nodoc:
    #
    # Sets file `#data` and `#size` at once.
    #
    # NOTE: Given data will be copied to a newly allocated memory.
    # NOTE: Used internally by the `CameraFolder#put` method.
    def data=(bytes : Bytes)
      # We need to allocate memory for the data outside of the GC
      # to avoid "pointer being freed was not allocated" error.
      #
      # It'll be freed by libgphoto2 in `gp_file_unref` / `gp_file_clean`,
      # through the `#finalize -> #close -> #free` call sequence.
      data = LibC.malloc(bytes.bytesize).as(UInt8*)
      data.copy_from(bytes.to_unsafe, bytes.size)

      set_data_and_size(data, bytes.bytesize)
      # Previous data (if any) has been freed by libgphoto2,
      # and the new data shouldn't get overwritten by a download.
      @data_and_size = {data, LibC::ULong.new(bytes.bytesize)}
      bytes
    end

    # Returns pointer file data.
    def data : UInt8*
      data_and_size.first
    end

    # Returns file size (in bytes).
    def size : UInt64
      data_and_size.last.to_u64
    end

    # Returns file `#data` as `Bytes`.
    def to_slice : Bytes
      data.to_slice(size)
    end

    # Reads file directly from the camera.
    def read : Bytes
      _read
    end

    # :nodoc:
    #
    # Returns the mime type of the file.
    def mime_type : String?
      if mime_type = get_mime_type.presence
        mime_type unless mime_type == UNKNOWN_MIME_TYPE
      end
    end

    # :nodoc:
    #
    # Sets the mime type of the file.
    #
    # NOTE: Used internally by the `CameraFolder#put` method.
    def mime_type=(type : String?)
      set_mime_type(type || UNKNOWN_MIME_TYPE)
      type
    end

    # :nodoc:
    #
    # Returns the modification time of the file.
    def mtime : Time?
      get_mtime
    end

    # :nodoc:
    #
    # Sets the modification time of the file.
    #
    # NOTE: Used internally by the `CameraFolder#put` method.
    def mtime=(time : Time?)
      set_mtime(time)
      time
    end

    # Returns an object containing information about the file.
    def info : CameraFileInfo
      get_info
    end

    private def new
      GPhoto2.check! \
        LibGPhoto2.gp_file_new(out ptr)
      self.ptr = ptr
    end

    # NOTE: libgphoto2 might hold its own references to the file
    # (i.e. the filesystem cache, after `CameraFolder#put`), so we
    # must only drop ours, instead of freeing it unconditionally.
    private def free
      GPhoto2.check! \
        LibGPhoto2.gp_file_unref(self)
      self.ptr = nil
      @data_and_size = nil
    end

    private getter data_and_size : {UInt8*, LibC::ULong} do
      get unless preview?
      get_data_and_size
    end

    private def get_data_and_size
      GPhoto2.check! \
        LibGPhoto2.gp_file_get_data_and_size(self, out data, out size)
      {data, size}
    end

    private def set_data_and_size(data, size)
      GPhoto2.check! \
        LibGPhoto2.gp_file_set_data_and_size(self, data, size)
    end

    private def get(type = Type::Normal)
      context.check! \
        LibGPhoto2.gp_camera_file_get(@camera, folder, name, type, self, context)
    end

    # Reads a chunk of the file starting at *offset* into *buffer*,
    # returning the number of bytes read.
    private def read_chunk(buffer : Bytes, offset : UInt64, type : Type) : UInt64
      size = buffer.size.to_u64

      context.check! \
        LibGPhoto2.gp_camera_file_read(@camera, folder, name, type,
        offset, buffer, pointerof(size), context)

      size
    end

    private def _read(type = Type::Normal) : Bytes
      buffer = Bytes.new(BUFFER_SIZE)
      offset = 0

      loop do
        # Grow geometrically to keep the number of copies low,
        # while requesting chunks of a constant size from the camera.
        if buffer.size - offset < BUFFER_SIZE
          buffer = Bytes.new(buffer.size * 2).tap(&.copy_from(buffer))
        end
        size = read_chunk(buffer[offset, BUFFER_SIZE], offset.to_u64, type)
        offset += size

        # A short read means we've reached the end of the file.
        break if size < BUFFER_SIZE
      end

      buffer[0, offset]
    end

    private def get_mime_type
      GPhoto2.check! \
        LibGPhoto2.gp_file_get_mime_type(self, out mime_type)
      String.new mime_type.not_nil!
    end

    private def set_mime_type(mime_type)
      GPhoto2.check! \
        LibGPhoto2.gp_file_set_mime_type(self, mime_type.check_no_null_byte)
    end

    private def get_mtime
      GPhoto2.check! \
        LibGPhoto2.gp_file_get_mtime(self, out mtime)
      Time.unix(mtime.to_i64) unless mtime == 0
    end

    private def set_mtime(mtime)
      GPhoto2.check! \
        LibGPhoto2.gp_file_set_mtime(self, mtime.try(&.to_unix) || 0)
    end

    private def get_info
      context.check! \
        LibGPhoto2.gp_camera_file_get_info(@camera, folder, name, out info, context)
      CameraFileInfo.new info
    end

    private def _delete
      context.check! \
        LibGPhoto2.gp_camera_file_delete(@camera, folder, name, context)
    end
  end
end
