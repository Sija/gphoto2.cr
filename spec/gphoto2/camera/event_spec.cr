require "../../spec_helper"

module GPhoto2
  describe Camera::Event do
    describe "#wait" do
      it "waits for an event" do
        with_directory_camera do |camera|
          # "Directory Browse" driver doesn't support events,
          # yet this ensures the code path compiles and calls into the library.
          error = expect_raises(GPhoto2::Error) do
            camera.wait(10.milliseconds)
          end
          error.code.should eq LibGPhoto2::GP_ERROR_NOT_SUPPORTED
        end
      end
    end

    describe "#wait_for" do
      it "waits for an event of the given type" do
        with_directory_camera do |camera|
          expect_raises(GPhoto2::Error) do
            camera.wait_for(:file_added, 10.milliseconds)
          end
        end
      end
    end
  end
end
