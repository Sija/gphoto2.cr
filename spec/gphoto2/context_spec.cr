require "../spec_helper"

module GPhoto2
  describe Context do
    describe "#finalize" do
      it "decrements the reference counter" do
        context = Context.new
        context.@ptr.should be_a Pointer(LibGPhoto2::GPContext)
        context.close
        context.@ptr.should be_a Nil
      end
    end
  end
end
