require "digest/sha1"

module GPhoto2
  class Camera
    module ID
      # Returns the ID of the camera.
      #
      # WARNING: this ID is not guaranteed to be unique.
      getter id : String do
        sn = self[:serialnumber]?.try(&.value?)
        id = "#{model}-#{sn || port}"

        Digest::SHA1.hexdigest(id)
      end
    end
  end
end
