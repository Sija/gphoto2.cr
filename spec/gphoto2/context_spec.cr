require "../spec_helper"

module GPhoto2
  describe Context do
    describe "#finalize" do
      it "decrements the reference counter" do
        context = Context.new
        context.ptr.should be_a Pointer(FFI::LibGPhoto2::GPContext)
        context.finalize
        context.ptr.should be_nil
      end
    end
  end
end