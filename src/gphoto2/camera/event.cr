module GPhoto2
  class Camera
    module Event
      def wait(timeout = 2000) : CameraEvent
        wait_for_event(timeout)
      end

      def wait_for(event_type : Symbol) : CameraEvent
        wait_for LibGPhoto2::CameraEventType.parse event_type.to_s
      end

      private def wait_for(event_type : LibGPhoto2::CameraEventType) : CameraEvent
        event = wait
        until event.type == event_type
          event = wait
        end
        event
      end

      private def wait_for_event(timeout : Int32) : CameraEvent
        GPhoto2.check! LibGPhoto2.gp_camera_wait_for_event(self, timeout, out type, out data_ptr, context)
        data =
          case type
          when .file_added?
            path = CameraFilePath.new(data_ptr.as(LibGPhoto2::CameraFilePath*))
            CameraFile.new(self, path.folder, path.name)
          when .folder_added?
            path = CameraFilePath.new(data_ptr.as(LibGPhoto2::CameraFilePath*))
            CameraFolder.new(self, "%s/%s" % [path.folder, path.name])
          when .unknown?
            data_ptr.null? ? nil : String.new(data_ptr.as(LibC::Char*))
          else
            nil
          end
        CameraEvent.new(type, data)
      end
    end
  end
end
