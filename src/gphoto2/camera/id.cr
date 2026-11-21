require "uuid"

module GPhoto2
  class Camera
    module ID
      UUID_NS = UUID.new("cc4daadf-37f5-4a30-8f1b-33a49a08e012")

      # Returns the serial number of the camera if present.
      def serialnumber : String?
        self[:serialnumber]?.try(&.value?).try(&.to_s)
      rescue ex : GPhoto2::Error
        # Camera driver doesn't support configuration
        raise ex unless ex.code == LibGPhoto2::GP_ERROR_NOT_SUPPORTED
      end

      # Returns the ID of the camera.
      #
      # WARNING: this ID is not guaranteed to be unique.
      getter id : UUID do
        id = "#{model}-#{serialnumber || port}"
        UUID.v5(id, UUID_NS)
      end
    end
  end
end
