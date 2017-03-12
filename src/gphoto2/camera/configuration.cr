module GPhoto2
  class Camera
    module Configuration
      # Returns camera `CameraWidget::Window` root configuration widget.
      getter window : CameraWidget::Window { get_config.as(CameraWidget::Window) }

      # Returns flattened `Hash` of camera attributes.
      #
      # ```
      # # List camera configuration keys.
      # camera.config.keys # => ["autofocusdrive", "manualfocusdrive", "controlmode", ...]
      # ```
      #
      # See also: `#[]` and `#[]=`
      getter config : Hash(String, CameraWidget::Base) { window.flatten }

      # Preserves config for a block call.
      #
      # ```
      # # Original values
      # camera[:aperture] # => 4
      # camera[:iso]      # => 400
      #
      # # Capture photo with different settings,
      # # while preserving original values
      # camera.preserving_config do
      #   1.upto(3) do |i|
      #     camera.update({
      #       aperture: 8,
      #       iso:      200 * i,
      #     })
      #     file = camera.capture
      #     file.save
      #   end
      # end
      #
      # # Original values are being preserved
      # camera[:aperture] # => 4
      # camera[:iso]      # => 400
      # ```
      def preserving_config(keys : Array(String | Symbol) = nil) : Void
        config_snapshot = keys ? config.select(keys.map &.to_s) : config
        config_snapshot = config_snapshot.reduce({} of String => String) do |memo, (key, widget)|
          memo[key] = widget.to_s rescue NotImplementedError
          memo
        end
        begin
          yield self
        ensure
          diff = config_snapshot.select { |key, value| self[key] != value }
          begin
            update diff unless diff.empty?
          rescue GPhoto2::Error
            reload
            update diff
          end
        end
      end

      # :nodoc:
      def preserving_config(*keys) : Void
        preserving_config(keys.to_a) { |camera| yield camera }
      end

      # Reloads camera configuration.
      #
      # All unsaved changes will be lost.
      #
      # ```
      # camera[:iso] # => 800
      # camera[:iso] = 200
      # camera.reload
      # camera[:iso] # => 800
      # ```
      def reload : Void
        @window.try &.close
        reset
        config
      end

      # Returns the attribute identified by *key*.
      #
      # See: `#config`
      #
      # ```
      # camera[:whitebalance].to_s  # => "Automatic"
      # camera["whitebalance"].to_s # => "Automatic"
      # ```
      def [](key : String | Symbol) : CameraWidget::Base
        config[key.to_s]
      end

      # ditto
      def []?(key : String | Symbol) : CameraWidget::Base?
        config[key.to_s]?
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

      # ```
      # iso = camera[:iso].as_radio
      # iso.value = iso.choices.first
      # camera << iso
      # ```
      def <<(widget : CameraWidget::Base) : self
        key = widget.name
        # set_single_config(key, widget)
        config[key] = widget
        @dirty = true
        self
      end

      # Updates the configuration on the camera.
      #
      # ```
      # camera[:iso] = 800
      # camera.save # => true
      # camera.save # => false (nothing to update)
      # ```
      def save : Bool
        return false unless dirty?
        set_config
        @dirty = false
        true
      end

      # Updates camera attributes from the given
      # `Hash`, `NamedTuple` or keyword arguments (`**kwargs`)
      # and saves the configuration.
      #
      # ```
      # camera[:iso]           # => 800
      # camera[:shutterspeed2] # => "1/30"
      #
      # # **kwargs
      # camera.update(iso: 400, shutterspeed2: "1/60")
      # # NamedTuple
      # camera.update({iso: 400, shutterspeed2: "1/60"})
      # # Hash
      # camera.update({"iso" => 400, "shutterspeed2" => "1/60"})
      #
      # camera[:iso]           # => 400
      # camera[:shutterspeed2] # => "1/60"
      # ```
      def update(attributes) : Bool
        attributes.each do |key, value|
          self[key] = value
        end
        save
      end

      # :nodoc:
      def update(**attributes)
        update(attributes)
      end

      # Returns `true` if any attributes have unsaved changes.
      #
      # ```
      # camera.dirty? # => false
      # camera[:iso] = 400
      # camera.dirty? # => true
      # ```
      getter? dirty = false

      private def reset : Void
        @window = nil
        @config = nil
        @dirty = false
      end

      private def get_config
        context.check! LibGPhoto2.gp_camera_get_config(self, out window, context)
        CameraWidget.factory(window)
      end

      private def set_config
        context.check! LibGPhoto2.gp_camera_set_config(self, window, context)
      end

      private def set_single_config(name, widget)
        context.check! LibGPhoto2.gp_camera_set_single_config(self, name, widget, context)
      end
    end
  end
end
