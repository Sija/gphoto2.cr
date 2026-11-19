module GPhoto2
  class Camera
    module Capture
      alias Type = LibGPhoto2::CameraCaptureType

      # ```
      # # Take a photo.
      # file = camera.capture
      #
      # # And save it to the current working directory.
      # file.save
      # ```
      def capture : CameraFile
        capture :image
      end

      # :nodoc:
      def capture(type : Type) : CameraFile
        save
        path = _capture(type).to_path
        CameraFile.new(self, path)
      end

      # Triggers a capture and immediately returns.
      #
      # A camera trigger is the first half of a `#capture`. Instead of
      # returning a `GPhoto2::CameraFile`, a trigger immediately returns and
      # the caller has to poll for events.
      #
      # ```
      # camera.trigger
      # event = camera.wait_for(:file_added)
      # event.data # => CameraFile
      # ```
      def trigger : Nil
        save
        trigger_capture
      end

      # Captures a preview from the camera.
      #
      # Previews are not stored on the camera but are returned as data in a
      # `GPhoto2::CameraFile`.
      #
      # ```
      # # Capturing a preview is like using `Camera#capture`.
      # file = camera.preview
      #
      # # The resulting file isn't stored on the camera.
      # file.preview? # => true
      #
      # # But it will contain image data from the camera.
      # file.to_slice # => Bytes[255, 216, 255, 219, 0, 132, 0, 6, ...]
      # ```
      def preview : CameraFile
        save
        capture_preview
      end

      private def _capture(type)
        # Zeroed (unlike `out` variables), since drivers aren't guaranteed
        # to fill it in, which would leave it with leftover stack contents
        path = LibGPhoto2::CameraFilePath.new
        context.check! \
          LibGPhoto2.gp_camera_capture(self, type, pointerof(path), context)

        CameraFilePath.new(path).tap do |file_path|
          if file_path.name.empty?
            raise Error.new("Camera did not report the captured file path", LibGPhoto2::GP_ERROR)
          end
        end
      end

      private def capture_preview
        file = CameraFile.new(self)
        context.check! \
          LibGPhoto2.gp_camera_capture_preview(self, file, context)
        file
      end

      private def trigger_capture
        context.check! \
          LibGPhoto2.gp_camera_trigger_capture(self, context)
      end
    end
  end
end
