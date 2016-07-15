module GPhoto2
  class Camera
    module Configuration
      @dirty : Bool = false
      @window : CameraWidget?
      @config : Hash(String, CameraWidget)?

      def initialize(model, port)
        super
        reset
      end

      def window
        @window ||= get_config
      end

      # ```
      # # List camera configuration keys.
      # camera.config.keys # => ["autofocusdrive", "manualfocusdrive", "controlmode", ...]
      # ```
      def config
        @config ||= window.flatten
      end

      # Reloads the camera configuration.
      #
      # All unsaved changes will be lost.
      #
      # ```
      # camera["iso"] # => 800
      # camera["iso"] = 200
      # camera.reload
      # camera["iso"] # => 800
      # ```
      def reload : Void
        reset
        config
      end

      # ```
      # camera["whitebalance"].to_s # => "Automatic"
      # ```
      def [](key : String | Symbol)
        config[key.to_s]
      end

      # ```
      # iso = camera["iso"].as(GPhoto2::RadioCameraWidget)
      # iso.value = "800"
      # camera["iso"] = iso
      # ```
      def []=(key : String | Symbol, widget : CameraWidget)
        key = key.to_s
        set_single_config(key, widget)
        config[key] = widget
      end

      # Updates the attribute identified by *key* with the specified *value*.
      #
      # This marks the configuration as "dirty", meaning a call to `#save` is
      # needed to actually update the configuration on the camera.
      #
      # ```
      # camera["iso"] = 800
      # camera["f-number"] = "f/2.8"
      # camera["shutterspeed2"] = "1/60"
      # ```
      def []=(key : String | Symbol, value)
        self[key].value = value
        @dirty = true
        value
      end

      # Updates the configuration on the camera.
      #
      # ```
      # camera["iso"] = 800
      # camera.save # => true
      # camera.save # => false (nothing to update)
      # ```
      def save
        return false unless dirty?
        set_config
        @dirty = false
        true
      end

      # Updates the attributes of the camera from the given Hash and saves the
      # configuration.
      #
      # ```
      # camera["iso"]           # => 800
      # camera["shutterspeed2"] # => "1/30"
      #
      # camera.update({iso: 400, shutterspeed2: "1/60"})
      #
      # camera["iso"]           # => 400
      # camera["shutterspeed2"] # => "1/60"
      # ```
      def update(attributes)
        attributes.each do |key, value|
          self[key] = value
        end
        save
      end

      # ```
      # camera.dirty? # => false
      # camera["iso"] = 400
      # camera.dirty? # => true
      # ```
      def dirty?
        @dirty
      end

      private def reset
        @window = nil
        @config = nil
        @dirty = false
      end

      private def get_config
        GPhoto2.check! LibGPhoto2.gp_camera_get_config(self, out window, context)
        CameraWidget.factory window
      end

      private def set_config
        GPhoto2.check! LibGPhoto2.gp_camera_set_config(self, window, context)
      end

      private def set_single_config(name : String, widget : CameraWidget)
        GPhoto2.check! LibGPhoto2.gp_camera_set_single_config(self, name, widget, context)
      end
    end
  end
end
