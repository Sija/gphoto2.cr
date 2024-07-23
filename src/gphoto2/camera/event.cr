module GPhoto2
  class Camera
    # Provides methods to wait for events.
    module Event
      def wait(timeout : Time::Span = 2.seconds) : CameraEvent
        wait_for_event(timeout)
      end

      # Waits for the specified event type and returns the event.
      #
      # NOTE: this method is blocking.
      def wait_for(event_type : CameraEvent::Type, timeout : Time::Span = 2.seconds) : CameraEvent
        event = wait timeout
        until event.type == event_type
          event = wait timeout
        end
        event
      end

      private def wait_for_event(timeout : Time::Span) : CameraEvent
        timeout_ms = timeout.total_milliseconds.to_i
        context.check! \
          LibGPhoto2.gp_camera_wait_for_event(self, timeout_ms, out type, out data_ptr, context)
        data =
          case type
          when .file_added?
            CameraFile.new(self, build_path(data_ptr))
          when .folder_added?
            CameraFolder.new(self, build_path(data_ptr))
          when .unknown?
            String.new(data_ptr.as(LibC::Char*)) if data_ptr
          end
        CameraEvent.new(type, data)
      end

      private def build_path(data_ptr)
        CameraFilePath.new(data_ptr.as(LibGPhoto2::CameraFilePath*)).to_path
      end
    end
  end
end
