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
        # NOTE: Same as `#dirty?`, but scanning the widgets only once
        return false unless @dirty || @window
        pending = config.select { |_, widget| widget.changed? }
        return false unless @dirty || pending.present?

        begin
          set_config
        rescue ex
          keep_pending(pending)
          raise ex
        end
        # Drivers (i.e. PTP) clear the flags of the saved widgets themselves,
        # make sure none are left behind, so the config isn't dirty anymore.
        # NOTE: The rest of the widgets has been just checked to be unflagged.
        pending.each_value(&.changed = false)
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
      #
      # NOTE: When any of the attributes can't be set (i.e. due to an invalid
      # value), the ones set before are reverted and the error is reraised.
      def update(attributes) : Bool
        # The changed flags of the widgets are restored one by one (see below),
        # so only the flag tracking the changes made by `#[]=` and `#<<` is kept
        was_dirty = @dirty
        previous = Array({CameraWidget::Base, typeof(self[""].raw_value), Bool}).new
        begin
          attributes.each do |key, value|
            widget = self[key]
            previous << {widget, widget.raw_value, widget.changed?}
            self[key] = value
          end
        rescue ex
          # Otherwise the values set so far would be saved along with any
          # subsequent `#save` (i.e. the one implicitly done by `#capture`)
          previous.reverse_each do |widget, raw_value, changed|
            widget.value = raw_value unless raw_value.nil?
            # Restoring the value marks it as changed again, which would
            # make drivers save it along with the next `#save`
            widget.changed = changed
          end
          @dirty = was_dirty
          raise ex
        end
        save
      end

      # :nodoc:
      def update(**attributes)
        update(attributes)
      end

      @dirty = false

      # Returns `true` if any attributes have unsaved changes, including
      # the ones changed on the widgets directly (i.e. using
      # `CameraWidget::Base#value=` or `CameraWidget::Radio#>>`).
      #
      # ```
      # camera.dirty? # => false
      # camera[:iso] = 400
      # camera.dirty? # => true
      # ```
      def dirty? : Bool
        return true if @dirty
        return false unless @window

        # Widgets changed directly are flagged by libgphoto2 only
        config.each_value.any?(&.changed?)
      end

      # Flags the *widgets* whose values didn't make it to the camera
      # as changed again, so that they're saved by the next `#save`.
      #
      # NOTE: Drivers (i.e. PTP, for Canon EOS cameras) clear the flags of
      # the widgets they failed to save too, without telling which ones
      # were saved, hence the comparison with the values on the camera.
      private def keep_pending(widgets : Hash(String, CameraWidget::Base)) : Nil
        saved_window = get_config rescue nil
        saved_config = saved_window.try &.flatten

        widgets.each do |key, widget|
          next if widget.changed?
          if saved_config && (saved_widget = saved_config[key]?)
            next if saved_widget.raw_value.to_s == widget.raw_value.to_s
          end
          widget.changed = true
        end
      ensure
        # Free the widget tree right away, since it's allocated outside
        # of the GC heap, and therefore doesn't trigger garbage collection
        saved_window.try &.close
      end

      private def restore_config(snapshot : Hash(String, String)) : Nil
        # Unsaved values don't reflect the camera state, in which case
        # the values need to be compared with the ones on the camera too
        saved_window = get_config if dirty?
        diff = begin
          saved_config = saved_window.try(&.flatten) || config

          snapshot.select do |key, value|
            # Settings might come and go (i.e. depending on the camera mode),
            # those which are gone can't be restored anymore
            next false unless (widget = self[key]?) &&
                              (saved_widget = saved_config[key]?)

            widget.raw_value.to_s != value ||
              saved_widget.raw_value.to_s != value
          end
        ensure
          # See `#keep_pending`
          saved_window.try &.close
        end
        return if diff.empty?

        begin
          update diff
        rescue GPhoto2::Error
          reload
          # Reloaded settings might be gone as well
          update diff.select { |key, _| self[key]? }
        end
      end

      private def reset : Nil
        @window = nil
        @config = nil
        @dirty = false
      end

      private def get_config
        # Null-initialized (unlike `out` variables), since drivers aren't
        # guaranteed to set it, which would leave it pointing to garbage
        window = Pointer(LibGPhoto2::CameraWidget).null
        context.check! \
          LibGPhoto2.gp_camera_get_config(self, pointerof(window), context)

        if window.null?
          raise Error.new("Camera did not report its configuration", LibGPhoto2::GP_ERROR)
        end
        CameraWidget.factory(window)
      end

      private def set_config
        context.check! \
          LibGPhoto2.gp_camera_set_config(self, window, context)
      end
    end
  end
end
