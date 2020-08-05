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
        String.new summary.text.to_unsafe
      end

      # Retrieves the manual for given camera.
      #
      # This manual typically contains information about using the camera.
      def manual_text : String
        context.check! \
          LibGPhoto2.gp_camera_get_manual(self, out manual, context)
        String.new manual.text.to_unsafe
      end

      # Retrieves information about the camera driver.
      #
      # Typically, this information contains name and address of the author,
      # acknowledgements, etc.
      def about_text : String
        context.check! \
          LibGPhoto2.gp_camera_get_about(self, out about, context)
        String.new about.text.to_unsafe
      end
    end
  end
end
