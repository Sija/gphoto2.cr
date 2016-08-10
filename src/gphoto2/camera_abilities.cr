require "./managed_struct"

module GPhoto2
  class CameraAbilities
    include GPhoto2::ManagedStruct(LibGPhoto2::CameraAbilities)

    @camera_abilities_list : CameraAbilitiesList
    @index : Int32

    delegate :status, :device_type, :operations, :file_operations, :folder_operations,
      to: wrapped

    def self.find(model : String) : self
      context = Context.new

      camera_abilities_list = CameraAbilitiesList.new(context)
      abilities = camera_abilities_list[model]

      context.close
      abilities
    end

    def initialize(@camera_abilities_list : CameraAbilitiesList, @index : Int32)
      get_abilities
    end

    private def get_abilities
      GPhoto2.check! LibGPhoto2.gp_abilities_list_get_abilities(
        @camera_abilities_list,
        @index,
        self
      )
    end
  end
end
