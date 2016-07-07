require "./struct"

module GPhoto2
  class Context; end
  class CameraAbilitiesList; end

  class CameraAbilities
    include GPhoto2::Struct(LibGPhoto2::CameraAbilities)

    @camera_abilities_list : CameraAbilitiesList
    @index : Int32

    def self.find(model : String)
      context = Context.new

      camera_abilities_list = CameraAbilitiesList.new(context)
      index = camera_abilities_list.lookup_model(model)
      abilities = camera_abilities_list[index]

      context.finalize
      abilities
    end

    def initialize(@camera_abilities_list, @index)
      get_abilities
    end

    private def get_abilities
      # FIXME: where else should it be changed?
      ptr = Pointer(LibGPhoto2::CameraAbilities).malloc
      GPhoto2.check! LibGPhoto2.gp_abilities_list_get_abilities(
        @camera_abilities_list,
        @index,
        ptr
      )
      self.ptr = ptr
    end
  end
end