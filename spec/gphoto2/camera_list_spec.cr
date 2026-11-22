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

    describe "#each" do
      it "yields the entries in order" do
        list = CameraList.new
        GPhoto2.check! LibGPhoto2.gp_list_append(list, "foo", "bar")
        GPhoto2.check! LibGPhoto2.gp_list_append(list, "baz", nil)

        entries = [] of CameraList::Entry
        list.each { |entry| entries << entry }
        entries.should eq list.to_a
      end

      it "makes the list enumerable" do
        list = CameraList.new
        GPhoto2.check! LibGPhoto2.gp_list_append(list, "foo", "bar")
        GPhoto2.check! LibGPhoto2.gp_list_append(list, "baz", "qux")

        list.map(&.name).should eq %w[foo baz]
        list.find(&.value.== "qux").try(&.name).should eq "baz"
        list.empty?.should be_false
        CameraList.new.empty?.should be_true
      end
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

    describe "#wrapped" do
      it "raises after the list has been closed" do
        list = CameraList.new
        list.wrapped.used.should eq 0
        list.close
        expect_raises(GPhoto2::Exception, "GPhoto2::CameraList is closed or not initialized") do
          list.wrapped
        end
      end
    end
  end
end
