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

    # Maximum size of a chunk requested from the camera at once by `#read`
    # and `#write_to`, the same as used by libgphoto2 itself for reading
    # files in chunks (i.e. in its PTP driver). Larger chunks mean fewer
    # round trips, while some cameras might not handle these too large.
    CHUNK_SIZE = 1024 * 1024

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
    # Raises `ArgumentError` if *path* points to a folder, rather than
    # a file (i.e. it's empty, ends with `/`, `.` or `..`).
    #
    # NOTE: Memory is allocated lazily, on first access to `#ptr`.
    def initialize(@camera, path : Path | String)
      if GPhoto2.folder_path?(path)
        raise ArgumentError.new("Invalid file path: #{path.to_s.inspect}")
      end
      @path = GPhoto2.absolute_path(path)
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

    # Returns file name.
    def name
      @path.basename
    end

    # Returns path of the folder containing the file.
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
    #
    # NOTE: An existing file is overwritten only once the whole file has
    # been downloaded, while a new one is written as the data is read from
    # the camera (see `#write_to`) into a temporary file, which is renamed
    # to *path* once done, or removed if that fails.
    def save(path : Path | String = name) : Nil
      path = Path[path] if path.is_a?(String)
      path /= name if path.ends_with_separator? || Dir.exists?(path)

      # NOTE: Symlinks (even the broken ones) are existing files too,
      # which must not be removed on failure
      if File.exists?(path) || File.symlink?(path)
        # Download the data first, so that a failed download
        # doesn't leave an existing file truncated
        data
        File.open(path, "w") { |file| write_to(file) }
      else
        # There's nothing to truncate, so the data is written as read
        # from the camera (see `#write_to`), without holding all of it
        # in memory, into a temporary file next to the target one.
        created_dirs = missing_dirs(path.parent)
        Dir.mkdir_p(path.dirname)

        # NOTE: Unlike `File.tempfile` (creating it with `0o600` permissions),
        # it's created with the same permissions as the target one would be,
        # under a random name, which can't be guessed (nor clash) in practice.
        # It's not named after the target one, since that one might take up
        # (almost) all of the file name length supported by the filesystem.
        tempfile = path.parent / ".gphoto2-#{Random::Secure.hex(8)}.part"
        begin
          File.open(tempfile, "w") { |file| write_to(file) }
          # Renaming replaces the target file atomically, including the one
          # created meanwhile (i.e. by another writer), as with existing files
          File.rename(tempfile, path)
        rescue ex
          # Cleaning up is best-effort only, which must not mask the original
          # exception, i.e. when something else has been written there since
          begin
            File.delete?(tempfile)
            # Deepest first, raising (and so stopping) at the non-empty ones
            created_dirs.each { |dir| Dir.delete?(dir) }
          rescue File::Error
          end
          raise ex
        end
      end
    end

    # Returns the directories missing along the given *dir* path (itself
    # included), deepest first.
    private def missing_dirs(dir : Path) : Array(Path)
      dirs = [] of Path
      until Dir.exists?(dir) || dir.parent == dir
        dirs << dir
        dir = dir.parent
      end
      dirs
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

      begin
        set_data_and_size(data, bytes.bytesize)
      rescue ex
        # libgphoto2 takes over the data only when it succeeds
        LibC.free(data)
        raise ex
      end
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
    # Unless the data is at hand already (i.e. of previews, or after
    # accessing `#data`), it's read from the camera in chunks, so that the
    # whole file is never held in memory (i.e. for large videos). Camera
    # drivers not supporting that get the whole file downloaded instead.
    #
    # ```
    # file = camera.preview
    # file.write_to(STDOUT)
    # ```
    def write_to(io : IO) : Nil
      if @data_and_size || preview?
        write_data_to(io)
      else
        stream_to(io)
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
      if preview?
        raise Error.new "Preview files aren't stored on the camera",
          LibGPhoto2::GP_ERROR_NOT_SUPPORTED
      end
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

    # Writes `#data` to *io*, starting at *offset*.
    private def write_data_to(io : IO, offset : UInt64 = 0_u64) : Nil
      # Written in chunks, since `Bytes` can't hold more than `Int32::MAX`
      # bytes, while files (i.e. videos) might be larger than that
      ptr, size = data, self.size
      return if offset >= size

      ptr, remaining = ptr + offset, size - offset
      while remaining > 0
        chunk_size = Math.min(remaining, MAX_SLICE_SIZE.to_u64)
        io.write(ptr.to_slice(chunk_size))
        ptr += chunk_size
        remaining -= chunk_size
      end
    end

    # Writes the file to *io*, as read from the camera chunk by chunk.
    private def stream_to(io : IO, type : Type = :normal) : Nil
      buffer = Bytes.new(CHUNK_SIZE)
      offset = 0_u64

      loop do
        unless size = try_read_chunk(buffer, offset, type)
          # Drivers might not support reading files in chunks at all, or
          # past some offset (i.e. 4 GiB, for some PTP cameras), in which
          # case the file is downloaded as a whole, and written from where
          # the reading left off
          return write_data_to(io, offset)
        end
        # See `#_read`
        break if size.zero?

        io.write(buffer[0, size])
        offset += size
      end
    end

    # Reads a chunk of the file starting at *offset* into *buffer*,
    # returning the number of bytes read, or `nil` if the camera driver
    # doesn't support reading the file in chunks (at that *offset*).
    #
    # NOTE: Reading the first chunk might fail with other errors too, since
    # libgphoto2 passes the reads to the camera driver as-is, bypassing its
    # filesystem cache. That's the case for i.e. files captured to the
    # internal RAM of PTP cameras (stored under `/`, not on any of the
    # storages), which are available from the cache only. The file is then
    # downloaded as a whole instead, which fails on its own if it's not
    # available at all.
    private def try_read_chunk(buffer : Bytes, offset : UInt64, type : Type) : UInt64?
      size = buffer.size.to_u64
      rc = LibGPhoto2.gp_camera_file_read(@camera, folder, name, type,
        offset, buffer, pointerof(size), context)

      tolerated = context.check?(rc) do |code|
        if offset.zero?
          # Cancellation (see `Context#cancel_callback`) must not be retried
          code != LibGPhoto2::GP_ERROR_CANCEL
        else
          # Reading worked before, so any other error is a genuine one
          code == LibGPhoto2::GP_ERROR_NOT_SUPPORTED
        end
      end
      size if tolerated
    end

    private def _read(type = Type::Normal) : Bytes
      # Knowing the file size upfront allows allocating a buffer of the
      # right size (+1 byte, so that the end of file is detected without
      # growing it), otherwise it grows as needed.
      capacity = expected_size(type).try do |size|
        # NOTE: Capped before adding 1, since the size might be bogus
        (Math.min(size, MAX_PREALLOCATED_SIZE.to_u64 - 1) + 1).to_i32
      end

      # Starts with (at most) a single chunk, since reading the file in chunks
      # might turn out not to be supported (see below), in which case a buffer
      # of the expected size would have been allocated for nothing
      buffer = Bytes.new(Math.min(capacity || BUFFER_SIZE, CHUNK_SIZE))
      offset = 0

      loop do
        if offset == buffer.size
          if buffer.size == MAX_READ_SIZE
            # The file might end right at the limit, which needs to be
            # checked before giving up
            # (see below for the lack of support)
            unless size = try_read_chunk(Bytes.new(1), offset.to_u64, type)
              return to_slice
            end
            break if size.zero?
            raise Error.from_code(LibGPhoto2::GP_ERROR_FIXED_LIMIT_EXCEEDED)
          end
          # Grow geometrically to keep the number of copies low,
          # or to the expected size right away, if known
          new_size = Math.min(Math.max(buffer.size.to_i64 * 2, capacity || BUFFER_SIZE), MAX_READ_SIZE).to_i32
          buffer = Bytes.new(new_size).tap(&.copy_from(buffer))
        end
        # Request chunks of (at most) a constant size from the camera
        chunk_size = Math.min(CHUNK_SIZE, buffer.size - offset)
        size = try_read_chunk(buffer[offset, chunk_size], offset.to_u64, type)

        # Drivers might not support reading files in chunks (see `#stream_to`),
        # in which case the file is downloaded as a whole instead
        return to_slice unless size

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
      rc = LibGPhoto2.gp_camera_file_get_info(@camera, folder, name, out info, context)

      # Cancellation (see `Context#cancel_callback`) must not be mistaken
      # for the file info not being available
      return unless context.check?(rc, &.!= LibGPhoto2::GP_ERROR_CANCEL)

      file_info = CameraFileInfo.new(info)
      case type
      when .normal?  then file_info.file?.try(&.size)
      when .preview? then file_info.preview?.try(&.size)
      end
    end

    private def get_mime_type
      GPhoto2.check! \
        LibGPhoto2.gp_file_get_mime_type(self, out ptr)
      ptr ? String.new(ptr) : ""
    end

    private def set_mime_type(mime_type)
      GPhoto2.check! \
        LibGPhoto2.gp_file_set_mime_type(self, mime_type.check_no_null_byte)
    end

    private def get_mtime
      GPhoto2.check! \
        LibGPhoto2.gp_file_get_mtime(self, out mtime)
      GPhoto2.time_from(mtime) unless mtime == 0
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
