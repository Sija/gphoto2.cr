require "../spec_helper"

module GPhoto2
  private class StructSpecList
    include Struct(LibGPhoto2::CameraList)
  end

  describe Struct do
    it "returns null pointer when unset" do
      list = StructSpecList.new
      list.ptr.null?.should be_true
      list.to_unsafe.null?.should be_true
    end

    it "does not memoize the null pointer" do
      list = StructSpecList.new
      list.ptr
      list.ptr?.should be_nil
    end

    it "returns the wrapped pointer" do
      GPhoto2.check! LibGPhoto2.gp_list_new(out ptr)
      list = StructSpecList.new(ptr)
      list.ptr.should eq ptr
      list.ptr?.should eq ptr
      GPhoto2.check! LibGPhoto2.gp_list_free(ptr)
    end
  end
end
