require "uuid"

module GPhoto2
  class Camera
    module ID
      UUID_NS = UUID.new("cc4daadf-37f5-4a30-8f1b-33a49a08e012")

      # Returns the ID of the camera.
      #
      # WARNING: this ID is not guaranteed to be unique.
      getter id : UUID do
        sn = self[:serialnumber]?.try(&.value?)
        id = "#{model}-#{sn || port}"

        UUID.v5(id, UUID_NS)
      end
    end
  end
end
