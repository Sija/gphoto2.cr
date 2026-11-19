# Allows replacing the filesystem functions of an initialized camera,
# in order to simulate driver features not provided by
# the "Directory Browse" driver (i.e. partial file reads).
@[Link("gphoto2")]
lib LibGPhoto2Spec
  alias ReadFileFunc = LibGPhoto2::CameraFilesystem*, LibC::Char*, LibC::Char*, LibGPhoto2::CameraFileType, LibC::UInt64T, LibC::Char*, LibC::UInt64T*, Void*, LibGPhoto2::GPContext* -> LibC::Int

  struct CameraFilesystemFuncs
    file_list_func : Void*
    folder_list_func : Void*
    put_file_func : Void*
    delete_all_func : Void*
    get_info_func : Void*
    set_info_func : Void*
    make_dir_func : Void*
    remove_dir_func : Void*
    get_file_func : Void*
    read_file_func : ReadFileFunc
    del_file_func : Void*
    storage_info_func : Void*
    unused : Void*[31]
  end

  fun gp_filesystem_set_funcs(fs : LibGPhoto2::CameraFilesystem*, funcs : CameraFilesystemFuncs*, data : Void*) : LibC::Int
end

module GPhoto2::SpecHelpers
  # Makes *camera* serve partial reads of any file from *data*.
  def stub_file_read(camera : Camera, data : Bytes) : Nil
    # Make sure the driver is initialized, so it doesn't override our functions.
    camera.filesystem.folders

    funcs = LibGPhoto2Spec::CameraFilesystemFuncs.new
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
    GPhoto2.check! LibGPhoto2Spec.gp_filesystem_set_funcs(camera.wrapped.fs, pointerof(funcs), box)
  end

  # Keeps the boxed data from being garbage-collected.
  STUBS = [] of Void*
end
