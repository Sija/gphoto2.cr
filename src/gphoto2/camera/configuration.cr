module GPhoto2
  class Camera
    # Provides access to camera configuration.
    module Configuration
      # Returns camera root configuration widget.
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
      #
      # Returns the value of the block.
      #
      # Raises `KeyError` if any of the given *keys* doesn't exist.
      def preserving_config(keys : Enumerable(String | Symbol)? = nil, &)
        config_snapshot =
          if keys
            # Unknown keys (i.e. typos) would otherwise go silently unpreserved
            keys.to_h { |key| {key.to_s, self[key]} }
          else
            config
          end

        config_snapshot =
          config_snapshot.reduce({} of String => String) do |memo, (key, widget)|
            # Read-only values (i.e. battery level, or the number of
            # available shots) can't be restored and change on their own.
            next memo if widget.readonly?

            # Use raw values, so that the empty ones (i.e. `None`) are restored too
            unless (value = widget.raw_value).nil?
              memo[key] = value.to_s
            end
            memo
          end

        raised = false
        begin
          yield self
        rescue ex
          raised = true
          # Don't let a failed restore mask the original exception
          restore_config(config_snapshot) rescue nil
          raise ex
        ensure
          # NOTE: `ensure` also covers leaving the block with `break`
          restore_config(config_snapshot) unless raised
        end
      end

      # :nodoc:
      def preserving_config(*keys, &)
        preserving_config(keys) { |camera| yield camera }
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
      def reload : Nil
        # NOTE: The previous widget tree is not freed explicitly, since its
        # widgets might still be in use; it gets freed by the GC instead.
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

      # :ditto:
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

      # Updates the attribute with the value of the given *widget*,
      # matched by its name.
      #
      # ```
      # iso = camera[:iso].as_radio
      # iso.value = iso.choices.first
      # camera << iso
      # ```
      def <<(widget : CameraWidget::Base) : self
        own_widget = self[widget.name]

        # Widgets not belonging to our configuration tree would be
        # ignored by `#save`, so their value needs to be copied over.
        own_widget.copy_value_from(widget) unless own_widget.same?(widget)

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

      private def restore_config(snapshot : Hash(String, String)) : Nil
        # Unsaved values don't reflect the camera state, in which case
        # the values need to be compared with the ones on the camera too
        saved_config = dirty? ? get_config.flatten : config

        diff = snapshot.select do |key, value|
          # Settings might come and go (i.e. depending on the camera mode),
          # those which are gone can't be restored anymore
          next false unless (widget = self[key]?) &&
                            (saved_widget = saved_config[key]?)

          widget.raw_value.to_s != value ||
            saved_widget.raw_value.to_s != value
        end
        return if diff.empty?

        begin
          update diff
        rescue GPhoto2::Error
          reload
          update diff
        end
      end

      private def reset : Nil
        @window = nil
        @config = nil
        @dirty = false
      end

      private def get_config
        context.check! \
          LibGPhoto2.gp_camera_get_config(self, out window, context)
        CameraWidget.factory(window)
      end

      private def set_config
        context.check! \
          LibGPhoto2.gp_camera_set_config(self, window, context)
      end
    end
  end
end
