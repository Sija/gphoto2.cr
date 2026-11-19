require "../spec_helper"

module GPhoto2
  describe CameraList do
    it "is empty by default" do
      list = CameraList.new
      list.size.should eq 0
      list.to_a.should be_empty
    end

    it "returns appended entries" do
      list = CameraList.new
      GPhoto2.check! LibGPhoto2.gp_list_append(list, "foo", "bar")
      GPhoto2.check! LibGPhoto2.gp_list_append(list, "baz", nil)

      list.size.should eq 2
      list.to_a.should eq [
        CameraList::Entry.new("foo", "bar"),
        CameraList::Entry.new("baz", ""),
      ]
    end

    describe "#close" do
      it "frees the list" do
        list = CameraList.new
        list.close
        list.ptr?.should be_nil
        # closing again is a no-op
        list.close
      end
    end
  end
end
