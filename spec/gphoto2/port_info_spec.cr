require "../spec_helper"

module GPhoto2
  describe PortInfoList do
    it "looks up port info by path" do
      list = PortInfoList.new
      list.lookup_path("disk:/tmp").should be >= 0
      list["disk:/tmp"].path.should eq "disk:/tmp"
    end

    it "raises on unknown port" do
      expect_raises(GPhoto2::Error) do
        PortInfoList.new["foo:bar"]
      end
    end
  end

  describe PortInfo do
    describe ".find" do
      it "returns port info of the given path" do
        info = PortInfo.find("disk:/tmp")
        info.path.should eq "disk:/tmp"
        info.type.disk?.should be_true
        info.name.should be_a String
      end
    end
  end
end
