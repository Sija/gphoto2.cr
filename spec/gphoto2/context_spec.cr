require "../spec_helper"

module GPhoto2
  describe Context do
    describe "#close" do
      it "decrements the reference counter" do
        context = Context.new
        context.@ptr.should be_a Pointer(LibGPhoto2::GPContext)
        context.close
        context.@ptr.should be_a Nil
      end
    end

    describe "callbacks" do
      it "calls the status callback" do
        context = Context.new
        messages = [] of String
        context.status_callback = ->(message : String) { messages << message; nil }
        LibGPhoto2.gp_context_status(context, "hello")
        messages.should eq ["hello"]
        context.close
      end

      it "calls the cancel callback" do
        context = Context.new
        context.cancel_callback = -> { true }
        LibGPhoto2.gp_context_cancel(context).cancel?.should be_true
        context.cancel_callback = -> { false }
        LibGPhoto2.gp_context_cancel(context).ok?.should be_true
        context.close
      end

      it "removes callbacks when set to nil" do
        context = Context.new
        calls = 0
        context.idle_callback = -> { calls += 1; nil }
        LibGPhoto2.gp_context_idle(context)
        context.idle_callback = nil
        LibGPhoto2.gp_context_idle(context)
        calls.should eq 1
        context.idle_callback?.should be_nil
        context.close
      end
    end

    describe "#check!" do
      it "returns the value on success" do
        context = Context.new
        context.check!(5).should eq 5
        context.close
      end

      it "raises with the last error message" do
        context = Context.new
        LibGPhoto2.gp_context_error(context, "Something went wrong")
        context.last_error.should eq "Something went wrong"

        error = expect_raises(Context::Error, "Something went wrong") do
          context.check!(LibGPhoto2::GP_ERROR_IO)
        end
        error.code.should eq LibGPhoto2::GP_ERROR_IO
        error.cause.try(&.message).should eq "I/O problem"
        context.last_error.should be_nil
        context.close
      end

      it "raises a generic error without the last error message" do
        context = Context.new
        expect_raises(GPhoto2::Error, "I/O problem") do
          context.check!(LibGPhoto2::GP_ERROR_IO)
        end
        context.close
      end
    end
  end
end
