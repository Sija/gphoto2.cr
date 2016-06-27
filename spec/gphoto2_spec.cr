require "./spec_helper"

describe GPhoto2 do
  describe ".result_as_string" do
    it "converts return code to proper string" do
      codez = {
        -107 => "Directory not found",
        -37  => "Error updating the port settings",
        -7   => "I/O problem"
      }
      codez.each do |code, string|
        GPhoto2.result_as_string(code).should eq(string)
      end
    end
  end

  describe ".check!" do
    context "the return code is not GP_OK" do
      it "raises GPhoto2::Error with a message and error code" do
        code = -1
        message = "Unspecified error (#{code})"

        expect_raises(GPhoto2::Error, message) { GPhoto2.check!(code) }
      end
    end
  end
end
