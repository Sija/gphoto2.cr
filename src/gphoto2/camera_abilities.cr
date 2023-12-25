require "./managed_struct"

module GPhoto2
  # Represents the abilities of a camera.
  class CameraAbilities
    include GPhoto2::ManagedStruct(LibGPhoto2::CameraAbilities)

    delegate :status, :device_type, :operations, :file_operations, :folder_operations,
      to: wrapped

    # Returns the abilities of the given *model* camera.
    def self.find(model : String) : self
      context = Context.new

      abilities_list = CameraAbilitiesList.new(context)
      abilities = abilities_list[model]

      context.close
      abilities
    end
  end
end
