module GPhoto2
  class Camera
    module Info
      # Retrieves a camera summary.
      #
      # This summary typically contains information like manufacturer,
      # pictures taken, or generally information that is not configurable.
      def summary_text : String
        context.check! \
          LibGPhoto2.gp_camera_get_summary(self, out summary, context)
        GPhoto2.string_from(summary.text)
      end

      # Retrieves the manual for given camera.
      #
      # This manual typically contains information about using the camera.
      def manual_text : String
        context.check! \
          LibGPhoto2.gp_camera_get_manual(self, out manual, context)
        GPhoto2.string_from(manual.text)
      end

      # Retrieves information about the camera driver.
      #
      # Typically, this information contains name and address of the author,
      # acknowledgements, etc.
      def about_text : String
        context.check! \
          LibGPhoto2.gp_camera_get_about(self, out about, context)
        GPhoto2.string_from(about.text)
      end
    end
  end
end
