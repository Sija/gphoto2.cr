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
      #
      # NOTE: The (32 KiB) struct is allocated on the heap (which zeroes it)
      # and read through a pointer, since both its zeroing constructor
      # (`LibGPhoto2::CameraText.new`, slowing down the compilation by
      # minutes) and copying its `text` (i.e. by `GPhoto2.string_from`,
      # by seconds) make LLVM generate huge amounts of code.
      private def camera_text(& : LibGPhoto2::CameraText* -> Int32) : String
        text = Pointer(LibGPhoto2::CameraText).malloc(1)
        context.check! yield text

        # `text` is the only field of the struct
        chars = Slice.new(text.as(LibC::Char*), sizeof(LibGPhoto2::CameraText))
        String.new(chars[0, chars.index(0_u8) || chars.size])
      end
    end
  end
end
