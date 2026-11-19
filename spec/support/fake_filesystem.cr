# Allows replacing the filesystem functions of an initialized camera,
# in order to simulate driver features not provided by
# the "Directory Browse" driver (i.e. partial file reads).
module GPhoto2::SpecHelpers
  # Makes *camera* serve partial reads of any file from *data*.
  def stub_file_read(camera : Camera, data : Bytes) : Nil
    # Make sure the driver is initialized, so it doesn't override our functions.
    camera.filesystem.folders

    funcs = LibGPhoto2::CameraFilesystemFuncs.new
    funcs.read_file_func = ->(_fs : LibGPhoto2::CameraFilesystem*, _folder : LibC::Char*, _file : LibC::Char*, _type : LibGPhoto2::CameraFileType, offset : LibC::UInt64T, buf : LibC::Char*, size : LibC::UInt64T*, user_data : Void*, _context : LibGPhoto2::GPContext*) {
      bytes = Box(Bytes).unbox(user_data)
      offset = Math.min(offset, bytes.size.to_u64)
      count = Math.min(size.value, bytes.size.to_u64 - offset)
      buf.copy_from(bytes.to_unsafe + offset, count)
      size.value = count
      LibGPhoto2::GP_OK
    }
    box = Box.box(data)
    STUBS << box
    GPhoto2.check! LibGPhoto2.gp_filesystem_set_funcs(camera.wrapped.fs, pointerof(funcs), box)
  end

  # Keeps the boxed data from being garbage-collected.
  STUBS = [] of Void*
end
