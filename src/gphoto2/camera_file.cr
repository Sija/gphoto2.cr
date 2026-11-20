require "./struct"

module GPhoto2
  class CameraFile
    include GPhoto2::Struct(LibGPhoto2::CameraFile)

    alias Type = LibGPhoto2::CameraFileType

    # The unknown mime type as specified by the libgphoto2.
    UNKNOWN_MIME_TYPE = "unknown/unknown"

    # Name of the preview files, used when the mime type of their data
    # is unknown (otherwise named after it, i.e. `capture_preview.ppm`).
    PREVIEW_FILENAME = "capture_preview.jpg"

    # Initial buffer size used in `#read`.
    BUFFER_SIZE = 256 * 1024

    # Maximum size of a file read by `#read`, since `Bytes`
    # can't hold more than `Int32::MAX` bytes.
    private MAX_READ_SIZE = Int32::MAX

    # Maximum size of a single chunk written by `#write_to`, since `Bytes`
    # can't hold more than `Int32::MAX` bytes.
    private MAX_SLICE_SIZE = Int32::MAX

    # Maximum buffer size allocated upfront in `#read`, based on the file
    # size reported by the camera, which might be bogus (i.e. `0xFFFFFFFF`).
    MAX_PREALLOCATED_SIZE = 64 * 1024 * 1024

    # Returns file path.
    getter path : Path

    protected getter camera : Camera
    protected delegate :context,
      to: @camera

    # Returns `true` if file is a preview (see `Camera#preview`).
    getter? preview : Bool = false

    # :nodoc:
    #
    # Names the preview after the name given to it by libgphoto2, which
    # reflects the mime type of its data (i.e. `capture_preview.ppm`),
    # keeping `PREVIEW_FILENAME` when the mime type is unknown.
    protected def adopt_preview_name : Nil
      return unless preview?

      GPhoto2.check! \
        LibGPhoto2.gp_file_get_name(self, out name_ptr)
      return if name_ptr.null?

      name = Path.posix(String.new(name_ptr))
      @path = name unless name.extension.empty?
    end

    # Relative *path* is resolved from the root folder.
    #
    # Raises `ArgumentError` if *path* points to the root folder.
    #
    # NOTE: Memory is allocated lazily, on first access to `#ptr`.
    def initialize(@camera, path : Path | String)
      @path = GPhoto2.absolute_path(path)
      if @path.to_s == "/"
        raise ArgumentError.new(%(Invalid file path: "/"))
      end
    end

    # Creates a preview file, which isn't stored on the camera.
    #
    # NOTE: Memory is allocated lazily, on first access to `#ptr`.
    def initialize(@camera)
      @path = Path.posix(PREVIEW_FILENAME)
      @preview = true
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

    # Returns the wrapped pointer, allocating it if needed.
    def ptr : LibGPhoto2::CameraFile*
      new unless ptr?
      super
    end

    # Finalizes object by freeing allocated memory.
    def finalize
      close
    end

    # NOTE: frees allocated memory.
    def close : Nil
      free if ptr?
    end

    # Saves file `#data` at given *path*, defaulting to file `#name`
    # in the current working directory.
    #
    # When *path* points to an existing directory (or ends with a path
    # separator), the file is saved inside of it, under its `#name`.
    def save(path : Path | String = name) : Nil
      path = Path[path] if path.is_a?(String)
      path /= name if path.ends_with_separator? || Dir.exists?(path)

      # Download the data first, so that a failed download
      # doesn't leave an existing file truncated
      data

      Dir.mkdir_p(path.dirname)
      File.open(path, "w") { |file| write_to(file) }
    end

    # Deletes file from the camera.
    #
    # Raises `GPhoto2::Error` for preview files, which aren't stored on the camera.
    def delete : Nil
      check_stored!
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

      # NOTE: `malloc(0)` might legitimately return a null pointer
      if data.null? && !bytes.empty?
        raise Error.from_code(LibGPhoto2::GP_ERROR_NO_MEMORY)
      end
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

    # Returns a copy of file `#data` as `Bytes`.
    #
    # NOTE: The data is copied, since the original buffer is owned by
    # libgphoto2, and freed along with the file (see `#close`).
    # Use `#write_to` or `#save` to avoid the copy.
    #
    # NOTE: Raises `OverflowError` for files larger than `Int32::MAX` bytes,
    # which `Bytes` can't hold; use `#write_to` or `#save` for those instead.
    def to_slice : Bytes
      data.to_slice(size).dup
    end

    # Writes file `#data` to the given *io*, without copying it first.
    #
    # ```
    # file = camera.preview
    # file.write_to(STDOUT)
    # ```
    def write_to(io : IO) : Nil
      # Written in chunks, since `Bytes` can't hold more than `Int32::MAX`
      # bytes, while files (i.e. videos) might be larger than that
      ptr, remaining = data, size
      while remaining > 0
        chunk_size = Math.min(remaining, MAX_SLICE_SIZE.to_u64)
        io.write(ptr.to_slice(chunk_size))
        ptr += chunk_size
        remaining -= chunk_size
      end
    end

    # Reads file directly from the camera.
    #
    # NOTE: Preview files aren't stored on the camera, so their
    # (already captured) data is returned instead, see `#to_slice`.
    def read : Bytes
      preview? ? to_slice : _read
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
    #
    # Raises `GPhoto2::Error` for preview files, which aren't stored on the camera.
    def info : CameraFileInfo
      check_stored!
      get_info
    end

    # Otherwise libgphoto2 fails with a cryptic "The path '.' is not absolute."
    private def check_stored! : Nil
      return unless preview?
      raise Error.new("Preview files aren't stored on the camera", LibGPhoto2::GP_ERROR_NOT_SUPPORTED)
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
      # Knowing the file size upfront allows allocating a buffer of the
      # right size (+1 byte, so that the end of file is detected without
      # growing it), otherwise it grows as needed.
      capacity = expected_size(type).try do |size|
        # NOTE: Capped before adding 1, since the size might be bogus
        (Math.min(size, MAX_PREALLOCATED_SIZE.to_u64 - 1) + 1).to_i32
      end
      buffer = Bytes.new(capacity || BUFFER_SIZE)
      offset = 0

      loop do
        if offset == buffer.size
          if buffer.size == MAX_READ_SIZE
            # The file might end right at the limit, which needs to be
            # checked before giving up
            break if read_chunk(Bytes.new(1), offset.to_u64, type).zero?
            raise Error.from_code(LibGPhoto2::GP_ERROR_FIXED_LIMIT_EXCEEDED)
          end
          # Grow geometrically to keep the number of copies low
          new_size = Math.min(Math.max(buffer.size.to_i64 * 2, BUFFER_SIZE), MAX_READ_SIZE).to_i32
          buffer = Bytes.new(new_size).tap(&.copy_from(buffer))
        end
        # Request chunks of (at most) a constant size from the camera
        chunk_size = Math.min(BUFFER_SIZE, buffer.size - offset)
        size = read_chunk(buffer[offset, chunk_size], offset.to_u64, type)

        # Drivers might return less data than requested before reaching
        # the end of the file, which is signaled by an empty read instead.
        break if size.zero?
        offset += size
      end

      # Don't hold on to the (mostly) unused memory, i.e. when
      # the expected size was larger than the actual one
      offset < buffer.size // 2 ? buffer[0, offset].dup : buffer[0, offset]
    end

    # Returns the size of the file as reported by the camera, if known.
    private def expected_size(type : Type) : UInt64?
      info = get_info
      case type
      when .normal?  then info.file?.try(&.size)
      when .preview? then info.preview?.try(&.size)
      end
    rescue ex : GPhoto2::Error
      # Cancellation (see `Context#cancel_callback`) must not be mistaken
      # for the file info not being available
      raise ex if ex.code == LibGPhoto2::GP_ERROR_CANCEL
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
