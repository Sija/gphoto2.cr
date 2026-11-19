require "../spec_helper"

module GPhoto2
  describe Port do
    describe "#info" do
      it "returns empty port info when none is assigned" do
        info = Port.new.info
        info.name.should eq ""
        info.path.should eq ""
        info.type.none?.should be_true
      end

      it "returns the assigned port info" do
        port = Port.new
        port.info = PortInfo.find("disk:/tmp")
        port.info.path.should eq "disk:/tmp"
      end
    end

    describe "#finalize" do
      it "frees the port" do
        port = Port.new
        port.finalize
        port.ptr?.should be_nil
      end

      it "does not raise when the port has not been allocated" do
        # i.e. when `#initialize` failed
        Port.allocate.finalize
      end
    end
  end
end
