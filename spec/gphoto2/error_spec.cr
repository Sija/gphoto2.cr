require "../spec_helper"

module GPhoto2
  describe Error do
    describe ".from_code" do
      it "builds an error with a message matching the code" do
        error = Error.from_code(LibGPhoto2::GP_ERROR_IO)
        error.code.should eq LibGPhoto2::GP_ERROR_IO
        error.message.should eq "I/O problem"
      end
    end

    describe "#to_s" do
      it "includes the message and the code" do
        Error.new("Boom", -1).to_s.should eq "Boom (-1)"
      end

      it "includes only the code when there's no message" do
        Error.new(nil, -1).to_s.should eq "(-1)"
        Error.new("", -1).to_s.should eq "(-1)"
      end
    end
  end

  describe NoDevicesError do
    it "has a default message" do
      NoDevicesError.new.message.should eq "No devices detected"
    end
  end
end
