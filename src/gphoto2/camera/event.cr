module GPhoto2
  class Camera
    # Provides methods to wait for events.
    module Event
      # Waits for the next event and returns it.
      #
      # Returns an event of `CameraEvent::Type::Timeout` type when no event
      # arrives within the given *timeout*.
      #
      # NOTE: this method is blocking.
      def wait(timeout : Time::Span = 2.seconds) : CameraEvent
        wait_for_event(timeout)
      end

      # Waits for events and yields each of them as it arrives, until
      # the block breaks out of the loop (or an error is raised).
      #
      # Timeout events (see `CameraEvent::Type::Timeout`) are skipped,
      # *timeout* being the time to wait for each of the events.
      #
      # Returns the value given to `break`.
      #
      # ```
      # camera.trigger
      # camera.each_event do |event|
      #   case event.type
      #   when .file_added?
      #     event.data.as(CameraFile).save
      #     break
      #   end
      # end
      # ```
      #
      # NOTE: This method is blocking, as is waiting for each of the events,
      # so the other fibers don't get to run in the meantime (unless built
      # with `-Dpreview_mt`). To stop waiting while there are no events, use
      # `#wait` to wait for them one by one, or set `Context#cancel_callback`,
      # which drivers (i.e. PTP) check while waiting, making this method
      # raise `GPhoto2::Error` with `GP_ERROR_CANCEL` code.
      def each_event(timeout : Time::Span = 2.seconds, &)
        loop do
          event = wait(timeout)
          yield event unless event.type.timeout?
        end
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

        # Drivers might leave the data untouched (i.e. on timeout), in which
        # case it must not end up as an indeterminate pointer passed to `free`,
        # and the type defaults to a timeout, as set by the bundled drivers
        type = CameraEvent::Type::Timeout
        data_ptr = Pointer(Void).null

        rc = LibGPhoto2.gp_camera_wait_for_event(self, timeout_ms, pointerof(type), pointerof(data_ptr), context)
        begin
          context.check!(rc)

          # Drivers aren't guaranteed to pass any data along with the event
          data =
            if data_ptr
              case type
              when .file_added?, .file_changed?
                file_path = camera_file_path(data_ptr)
                # Without a name, there's no file to point to
                CameraFile.new(self, file_path.to_path) unless file_path.name.empty?
              when .folder_added?
                CameraFolder.new(self, camera_file_path(data_ptr).to_path)
              when .unknown?
                String.new(data_ptr.as(LibC::Char*))
              end
            end
          CameraEvent.new(type, data)
        ensure
          # Event data is allocated by libgphoto2 and must be freed by the caller,
          # after a successful call (even when one of the callbacks raised)
          LibC.free(data_ptr) if data_ptr && GPhoto2.check?(rc)
        end
      end

      private def camera_file_path(data_ptr) : CameraFilePath
        CameraFilePath.new(data_ptr.as(LibGPhoto2::CameraFilePath*).value)
      end
    end
  end
end
