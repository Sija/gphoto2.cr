module GPhoto2
  class CameraFile; end
  class CameraFilePath; end

  class Camera
    module Capture
      # @example
      #   # Take a photo.
      #   file = camera.capture
      #
      #   # And save it to the current working directory.
      #   file.save
      #
      def capture(type = FFI::LibGPhoto2::CameraCaptureType::Image) : CameraFile
        save
        path = _capture(type)
        CameraFile.new(self, path.folder, path.name)
      end

      def capture(type : Symbol) : CameraFile
        capture FFI::LibGPhoto2::CameraCaptureType.parse type.to_s
      end

      # Triggers a capture and immedately returns.
      #
      # A camera trigger is the first half of a {#capture}. Instead of
      # returning a {GPhoto2::CameraFile}, a trigger immediately returns and
      # the caller has to poll for events.
      #
      # @example
      #   camera.trigger
      #   event = camera.wait_for(:file_added)
      #   event.data # => CameraFile
      #
      def trigger : Void
        save
        trigger_capture
      end

      # Captures a preview from the camera.
      #
      # Previews are not stored on the camera but are returned as data in a
      # {GPhoto2::CameraFile}.
      #
      # @example
      #   # Capturing a preview is like using `Camera#capture`.
      #   file = camera.preview
      #
      #   # The resulting file will have neither a folder nor name.
      #   file.preview?
      #   # => true
      #
      #   # But it will contain image data from the camera.
      #   file.data
      #   # => "\xFF\xD8\xFF\xDB\x00\x84\x00\x06..."
      #
      def preview : CameraFile
        save
        capture_preview
      end

      private def _capture(type : FFI::LibGPhoto2::CameraCaptureType) : CameraFilePath
        GPhoto2.check! FFI::LibGPhoto2.gp_camera_capture(self, type, out path, context)
        CameraFilePath.new pointerof(path)
      end

      private def capture_preview : CameraFile
        file = CameraFile.new self
        GPhoto2.check! FFI::LibGPhoto2.gp_camera_capture_preview(self, file, context)
        file
      end

      private def trigger_capture : Void
        GPhoto2.check! FFI::LibGPhoto2.gp_camera_trigger_capture(self, context)
      end
    end
  end
end
