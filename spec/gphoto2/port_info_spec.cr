require "../spec_helper"

module GPhoto2
  describe PortInfoList do
    it "returns number of entries" do
      PortInfoList.new.size.should be > 0
    end

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

    it "raises on paths containing a null byte" do
      expect_raises(ArgumentError, "String contains null byte") do
        PortInfoList.new.lookup_path("disk:\0/tmp")
      end
    end

    describe "#finalize" do
      it "does not raise when the list has not been allocated" do
        # i.e. when `#initialize` failed
        PortInfoList.allocate.finalize
      end
    end

    it "exposes the entries through the wrapped struct" do
      list = PortInfoList.new
      wrapped = list.wrapped
      # NOTE: The raw list also contains the (unnamed) generic entries,
      # which are skipped by `#size` and `#[]`.
      paths = Array.new(wrapped.count) do |i|
        String.new(wrapped.info[i].value.path)
      end
      paths.size.should be >= list.size
      paths.should contain list[0].path
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

      it "remains valid after the port info list is garbage-collected" do
        infos = Array.new(20) { |i| PortInfo.find("disk:/tmp/port-#{i}") }
        3.times do
          GC.collect
          Array.new(20) { PortInfoList.new }
        end
        GC.collect

        infos.each_with_index do |info, i|
          info.path.should eq "disk:/tmp/port-#{i}"
        end
      end
    end
  end
end
