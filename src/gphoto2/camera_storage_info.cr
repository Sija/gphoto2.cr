module GPhoto2
  # Represents information about a camera storage (i.e. a memory card).
  #
  # NOTE: Values not reported by the camera driver are `nil`.
  struct CameraStorageInfo
    alias Fields = LibGPhoto2::CameraStorageInfoFields
    alias Type = LibGPhoto2::CameraStorageType
    alias AccessType = LibGPhoto2::CameraStorageAccessType
    alias FilesystemType = LibGPhoto2::CameraStorageFilesystemType

    # Returns the set of fields reported by the camera driver.
    getter fields : Fields

    # Returns the base folder of the storage (i.e. `/store_00010001`),
    # which is `/` if the camera has a single storage only.
    getter base_dir : String?

    # Returns the label of the storage, similar to a DOS volume label.
    getter label : String?

    # Returns the description of the storage.
    getter description : String?

    # Returns the hardware type of the storage.
    getter type : Type?

    # Returns the type of the filesystem hierarchy of the storage.
    getter filesystem_type : FilesystemType?

    # Returns the access permissions of the storage.
    getter access : AccessType?

    # Returns the total capacity of the storage, in kilobytes.
    getter capacity_kbytes : UInt64?

    # Returns the free space of the storage, in kilobytes.
    getter free_kbytes : UInt64?

    # Returns the number of images that still fit on the storage,
    # as estimated by the camera.
    getter free_images : UInt64?

    def_equals_and_hash fields, base_dir, label, description, type,
      filesystem_type, access, capacity_kbytes, free_kbytes, free_images

    # Creates storage information from the given libgphoto2 *info*.
    def initialize(info : LibGPhoto2::CameraStorageInformation)
      @fields = fields = info.fields

      @base_dir = GPhoto2.string_from(info.basedir) if fields.base?
      @label = GPhoto2.string_from(info.label) if fields.label?
      @description = GPhoto2.string_from(info.description) if fields.description?
      @type = info.type if fields.storage_type?
      @filesystem_type = info.fstype if fields.filesystem_type?
      @access = info.access if fields.access?
      @capacity_kbytes = info.capacitykbytes.to_u64 if fields.max_capacity?
      @free_kbytes = info.freekbytes.to_u64 if fields.free_space_kbytes?
      @free_images = info.freeimages.to_u64 if fields.free_space_images?
    end

    # Returns `true` if files can be written to the storage, `false`
    # otherwise, or `nil` if the access permissions are not reported.
    def writable? : Bool?
      access.try(&.read_write?)
    end
  end
end
