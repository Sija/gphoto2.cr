module GPhoto2
  class Camera
    module Info
      # Retrieves a camera summary.
      #
      # This summary typically contains information like manufacturer,
      # pictures taken, or generally information that is not configurable.
      def summary_text : String
        camera_text do |text_ptr|
          LibGPhoto2.gp_camera_get_summary(self, text_ptr, context)
        end
      end

      # Retrieves the manual for given camera.
      #
      # This manual typically contains information about using the camera.
      def manual_text : String
        camera_text do |text_ptr|
          LibGPhoto2.gp_camera_get_manual(self, text_ptr, context)
        end
      end

      # Retrieves information about the camera driver.
      #
      # Typically, this information contains name and address of the author,
      # acknowledgements, etc.
      def about_text : String
        camera_text do |text_ptr|
          LibGPhoto2.gp_camera_get_about(self, text_ptr, context)
        end
      end

      # Yields a pointer to a zeroed `CameraText` to be filled in by the
      # driver, returning its contents.
      #
      # NOTE: Unlike `out` variables (which Crystal leaves uninitialized),
      # the text is zeroed, since drivers aren't guaranteed to fill it in.
      private def camera_text(& : LibGPhoto2::CameraText* -> Int32) : String
        text = LibGPhoto2::CameraText.new
        context.check! yield pointerof(text)
        GPhoto2.string_from(text.text)
      end
    end
  end
end
