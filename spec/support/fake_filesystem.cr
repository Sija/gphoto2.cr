# Allows replacing the filesystem functions of an initialized camera,
# in order to simulate driver features not provided by
# the "Directory Browse" driver (i.e. partial file reads).
module GPhoto2::SpecHelpers
  # Makes *camera* serve partial reads of any file from *data*.
  #
  # When *reported_size* is given, it's reported as the file size
  # (see `CameraFile#info`), otherwise file info is not available.
  def stub_file_read(camera : Camera, data : Bytes, reported_size : UInt64? = nil) : Nil
    # Make sure the driver is initialized, so it doesn't override our functions.
    # Listing the files also makes them known to the filesystem cache.
    (camera / "DCIM").files

    funcs = LibGPhoto2::CameraFilesystemFuncs.new

    if reported_size
      funcs.get_info_func = ->(_fs : LibGPhoto2::CameraFilesystem*, _folder : LibC::Char*, _file : LibC::Char*, info : LibGPhoto2::CameraFileInfo*, user_data : Void*, _context : LibGPhoto2::GPContext*) {
        _, size = Box({Bytes, UInt64?}).unbox(user_data)
        file_info = LibGPhoto2::CameraFileInfoFile.new

        # Without mtime, libgphoto2 would try to read it from the EXIF
        # data, using the (not stubbed) get_file_func
        file_info.fields = LibGPhoto2::CameraFileInfoFields.flags(Size, Mtime)
        file_info.size = size.not_nil!

        info.value = LibGPhoto2::CameraFileInfo.new(file: file_info)
        LibGPhoto2::GP_OK
      }
    end

    funcs.read_file_func = ->(_fs : LibGPhoto2::CameraFilesystem*, _folder : LibC::Char*, _file : LibC::Char*, _type : LibGPhoto2::CameraFileType, offset : LibC::UInt64T, buf : LibC::Char*, size : LibC::UInt64T*, user_data : Void*, _context : LibGPhoto2::GPContext*) {
      bytes, _ = Box({Bytes, UInt64?}).unbox(user_data)
      offset = Math.min(offset, bytes.size.to_u64)
      count = Math.min(size.value, bytes.size.to_u64 - offset)
      buf.copy_from(bytes.to_unsafe + offset, count)
      size.value = count
      LibGPhoto2::GP_OK
    }

    # NOTE: The type must be given explicitly, since it's `UInt64`
    # (not `UInt64?`) when the method is called with *reported_size*
    box = Box({Bytes, UInt64?}).box({data, reported_size})
    STUBS << box

    GPhoto2.check! \
      LibGPhoto2.gp_filesystem_set_funcs(camera.wrapped.fs, pointerof(funcs), box)
  end

  # Keeps the boxed data from being garbage-collected.
  STUBS = [] of Void*
end
