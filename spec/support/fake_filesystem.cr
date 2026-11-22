# Allows replacing the filesystem functions of an initialized camera,
# in order to simulate driver features not provided by
# the "Directory Browse" driver (i.e. partial file reads).
module GPhoto2::SpecHelpers
  # Data served by the stubbed filesystem functions.
  class StubbedFile
    getter data : Bytes
    getter reported_size : UInt64?
    getter max_read_size : UInt64?
    getter unsupported_from : UInt64?
    # Number of times the file has been downloaded as a whole.
    property downloads = 0

    def initialize(@data, @reported_size, @max_read_size, @unsupported_from)
    end
  end

  # Makes *camera* serve partial reads of any file from *data*.
  #
  # When *reported_size* is given, it's reported as the file size
  # (see `CameraFile#info`), otherwise file info is not available.
  #
  # When *max_read_size* is given, reads return at most that many
  # bytes, even when more were requested and are available.
  #
  # When *unsupported_from* is given, reads starting at that offset
  # (or past it) fail as not supported, like with some PTP cameras.
  #
  # Files are served as a whole (see `CameraFile#data`) from *data* as well,
  # counted by `StubbedFile#downloads` of the returned stub.
  def stub_file_read(camera : Camera, data : Bytes, reported_size : UInt64? = nil, max_read_size : UInt64? = nil, unsupported_from : UInt64? = nil) : StubbedFile
    # Make sure the driver is initialized, so it doesn't override our functions.
    # Listing the files also makes them known to the filesystem cache.
    (camera / "DCIM").files

    funcs = LibGPhoto2::CameraFilesystemFuncs.new

    if reported_size
      funcs.get_info_func = ->(_fs : LibGPhoto2::CameraFilesystem*, _folder : LibC::Char*, _file : LibC::Char*, info : LibGPhoto2::CameraFileInfo*, user_data : Void*, _context : LibGPhoto2::GPContext*) {
        size = Box(StubbedFile).unbox(user_data).reported_size
        file_info = LibGPhoto2::CameraFileInfoFile.new

        # Without mtime, libgphoto2 would try to read it from the EXIF
        # data, using the (not stubbed) get_file_func
        file_info.fields = LibGPhoto2::CameraFileInfoFields.flags(Size, Mtime)
        file_info.size = size.not_nil!

        info.value = LibGPhoto2::CameraFileInfo.new(file: file_info)
        LibGPhoto2::GP_OK
      }
    end

    funcs.read_file_func = ->(_fs : LibGPhoto2::CameraFilesystem*, _folder : LibC::Char*, _file : LibC::Char*, _type : LibGPhoto2::CameraFileType, offset : LibC::UInt64T, buf : LibC::Char*, size : LibC::UInt64T*, user_data : Void*, context : LibGPhoto2::GPContext*) {
      # Gives the callbacks (see `Context#idle_callback`) a chance to run
      LibGPhoto2.gp_context_idle(context)

      file = Box(StubbedFile).unbox(user_data)
      if (limit = file.unsupported_from) && offset >= limit
        LibGPhoto2::GP_ERROR_NOT_SUPPORTED
      else
        bytes = file.data
        offset = Math.min(offset, bytes.size.to_u64)
        count = Math.min(size.value, bytes.size.to_u64 - offset)
        count = Math.min(count, file.max_read_size || count)
        buf.copy_from(bytes.to_unsafe + offset, count)
        size.value = count
        LibGPhoto2::GP_OK
      end
    }

    funcs.get_file_func = ->(_fs : LibGPhoto2::CameraFilesystem*, _folder : LibC::Char*, _file : LibC::Char*, _type : LibGPhoto2::CameraFileType, camera_file : LibGPhoto2::CameraFile*, user_data : Void*, _context : LibGPhoto2::GPContext*) {
      file = Box(StubbedFile).unbox(user_data)
      file.downloads += 1
      bytes = file.data
      # Taken over (and freed) by libgphoto2
      buffer = LibC.malloc(bytes.size).as(UInt8*)
      buffer.copy_from(bytes.to_unsafe, bytes.size)
      LibGPhoto2.gp_file_set_data_and_size(camera_file, buffer, bytes.size)
    }

    stub = StubbedFile.new(data, reported_size, max_read_size, unsupported_from)
    box = Box.box(stub)
    STUBS << box

    GPhoto2.check! \
      LibGPhoto2.gp_filesystem_set_funcs(camera.wrapped.fs, pointerof(funcs), box)
    stub
  end

  # Keeps the boxed data from being garbage-collected.
  STUBS = [] of Void*
end
