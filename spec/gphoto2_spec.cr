require "./spec_helper"

describe GPhoto2 do
  describe ".library_version" do
    it "should have proper format" do
      GPhoto2.library_version.should match /^\d+(\.\d+){2,3}(-\w+)?$/
    end
  end

  describe ".result_as_string" do
    it "converts return code to proper string" do
      return_codes = {
        # general
        LibGPhoto2::GP_OK    => "No error",
        LibGPhoto2::GP_ERROR => "Unspecified error",
        # libgphoto2
        LibGPhoto2::GP_ERROR_IO        => "I/O problem",
        LibGPhoto2::GP_ERROR_IO_LOCK   => "Could not lock the device",
        LibGPhoto2::GP_ERROR_NO_MEMORY => "Out of memory",
        # libgphoto2_port
        LibGPhoto2::GP_ERROR_DIRECTORY_NOT_FOUND => "Directory not found",
        LibGPhoto2::GP_ERROR_CAMERA_BUSY         => "I/O in progress",
        LibGPhoto2::GP_ERROR_NO_SPACE            => "Not enough free space",
        # random
        -777 => "Unknown error",
         777 => "Unknown error",
      }
      return_codes.each do |code, string|
        GPhoto2.result_as_string(code).should eq string
      end
    end
  end

  describe ".check?" do
    context "the return code is GP_OK" do
      it "returns true" do
        GPhoto2.check?(LibGPhoto2::GP_OK).should be_true
      end
    end
    context "the return code is not GP_OK" do
      it "returns false" do
        GPhoto2.check?(LibGPhoto2::GP_ERROR).should be_false
      end
    end
    context "the return code is a value" do
      it "returns true" do
        GPhoto2.check?(10).should be_true
      end
    end
  end

  describe ".check!" do
    context "the return code is GP_OK" do
      it "should not raise" do
        (GPhoto2.check!(LibGPhoto2::GP_OK) rescue :raised).should_not eq :raised
      end
    end
    context "the return code is not GP_OK" do
      it "raises GPhoto2::Error with a message and error code" do
        code = LibGPhoto2::GP_ERROR
        message = "Unspecified error (#{code})"

        expect_raises(GPhoto2::Error, message) do
          GPhoto2.check!(code)
        end
      end
    end
    context "the return code is a value" do
      it "returns back the value" do
        GPhoto2.check!(10).should eq 10
      end
    end
  end
end
