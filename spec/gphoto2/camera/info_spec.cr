require "../../spec_helper"

module GPhoto2
  describe Camera::Info do
    it "returns summary, manual and about texts" do
      with_fake_camera do |camera|
        FakeDriver.text = "Hello, World!"
        camera.summary_text.should eq "Hello, World!"
        camera.manual_text.should eq "Hello, World!"
        camera.about_text.should eq "Hello, World!"
      end
    end
  end
end
