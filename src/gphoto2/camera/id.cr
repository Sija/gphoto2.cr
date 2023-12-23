require "digest/sha1"

module GPhoto2
  class Camera
    module ID
      getter id : String do
        sn = self[:serialnumber]?.try(&.value?)
        id = "#{model}-#{sn || port}"

        Digest::SHA1.hexdigest(id)
      end
    end
  end
end
