module GPhoto2
  class Camera
    # Provides methods to wait for events.
    module Event
      def wait(timeout : Time::Span = 2.seconds) : CameraEvent
        wait_for_event(timeout)
      end

      # Waits for the specified event type and returns the event.
      #
      # Raises `GPhoto2::Error` (with `GP_ERROR_TIMEOUT` code) when
      # no matching event arrives within the given *timeout*.
      #
      # NOTE: this method is blocking.
      def wait_for(event_type : CameraEvent::Type, timeout : Time::Span = 2.seconds) : CameraEvent
        remaining = timeout
        loop do
          event = nil
          remaining -= Time.measure { event = wait(remaining) }

          return event if event && event.type == event_type
          raise Error.from_code(LibGPhoto2::GP_ERROR_TIMEOUT) unless remaining.positive?
        end
      end

      private def wait_for_event(timeout : Time::Span) : CameraEvent
        # libgphoto2 takes a non-negative `int` number of milliseconds
        timeout_ms = timeout.total_milliseconds.clamp(0, Int32::MAX).to_i
        context.check! \
          LibGPhoto2.gp_camera_wait_for_event(self, timeout_ms, out type, out data_ptr, context)
        begin
          # Drivers aren't guaranteed to pass any data along with the event
          data =
            if data_ptr
              case type
              when .file_added?, .file_changed?
                CameraFile.new(self, build_path(data_ptr))
              when .folder_added?
                CameraFolder.new(self, build_path(data_ptr))
              when .unknown?
                String.new(data_ptr.as(LibC::Char*))
              end
            end
          CameraEvent.new(type, data)
        ensure
          # Event data is allocated by libgphoto2 and must be freed by the caller.
          LibC.free(data_ptr) if data_ptr
        end
      end

      private def build_path(data_ptr)
        CameraFilePath.new(data_ptr.as(LibGPhoto2::CameraFilePath*).value).to_path
      end
    end
  end
end
