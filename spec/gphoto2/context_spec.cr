require "../spec_helper"

module GPhoto2
  private class FinalizeCountingContext < Context
    class_property finalized = 0

    def finalize
      @@finalized += 1
      super
    end
  end

  describe Context do
    describe "#close" do
      it "decrements the reference counter" do
        context = Context.new
        context.@ptr.should be_a Pointer(LibGPhoto2::GPContext)
        context.close
        context.@ptr.should be_a Nil
      end
    end

    describe "#finalize" do
      it "frees the context" do
        context = Context.new
        context.finalize
        context.ptr?.should be_nil
      end

      it "gets called by the GC" do
        FinalizeCountingContext.finalized = 0
        100.times { FinalizeCountingContext.new }
        GC.collect
        FinalizeCountingContext.finalized.should be > 0
      end

      it "does nothing after close" do
        context = Context.new
        context.close
        context.finalize
        context.ptr?.should be_nil
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

      it "calls the error callback while tracking the last error" do
        context = Context.new
        messages = [] of String
        context.error_callback = ->(message : String) { messages << message; nil }
        LibGPhoto2.gp_context_error(context, "boom")
        messages.should eq ["boom"]
        context.last_error.should eq "boom"

        expect_raises(Context::Error, "boom") do
          context.check!(LibGPhoto2::GP_ERROR)
        end
        context.close
      end

      it "keeps tracking the last error after removing error callback" do
        context = Context.new
        context.error_callback = ->(_message : String) { nil }
        context.error_callback = nil
        context.error_callback?.should be_nil
        LibGPhoto2.gp_context_error(context, "boom")
        context.last_error.should eq "boom"
        context.close
      end

      it "keeps tracking the last error after clearing callbacks" do
        context = Context.new
        context.clear_callbacks
        LibGPhoto2.gp_context_error(context, "boom")
        context.last_error.should eq "boom"
        context.close
      end

      it "re-raises exceptions raised by callbacks from #check!" do
        context = Context.new
        context.status_callback = ->(message : String) { raise "oops: #{message}" }
        # Exceptions mustn't propagate through the C code
        LibGPhoto2.gp_context_status(context, "hello")

        expect_raises(::Exception, "oops: hello") do
          context.check!(LibGPhoto2::GP_OK)
        end
        # Exception is raised only once
        context.check!(LibGPhoto2::GP_OK).should eq LibGPhoto2::GP_OK
        context.close
      end

      it "re-raises the first exception raised by callbacks" do
        context = Context.new
        context.status_callback = ->(message : String) { raise "oops: #{message}" }
        LibGPhoto2.gp_context_status(context, "first")
        LibGPhoto2.gp_context_status(context, "second")

        expect_raises(::Exception, "oops: first") do
          context.check!(LibGPhoto2::GP_ERROR)
        end
        context.close
      end

      it "cancels the operation when the cancel callback raises" do
        context = Context.new
        failing = true
        context.cancel_callback = -> { raise "oops" if failing; false }
        LibGPhoto2.gp_context_cancel(context).cancel?.should be_true

        expect_raises(::Exception, "oops") do
          context.check!(LibGPhoto2::GP_ERROR_CANCEL)
        end
        context.close
      end

      it "re-raises exceptions raised by the error callback" do
        context = Context.new
        context.error_callback = ->(message : String) { raise "oops: #{message}" }
        LibGPhoto2.gp_context_error(context, "boom")
        context.last_error.should eq "boom"

        expect_raises(::Exception, "oops: boom") do
          context.check!(LibGPhoto2::GP_ERROR)
        end
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

      it "raises with all of the error messages reported during the call" do
        context = Context.new
        LibGPhoto2.gp_context_error(context, "PTP I/O Error")
        LibGPhoto2.gp_context_error(context, " ")
        LibGPhoto2.gp_context_error(context, "An error occurred in the io-library")
        context.last_error.should eq "An error occurred in the io-library"

        error = expect_raises(Context::Error) do
          context.check!(LibGPhoto2::GP_ERROR_IO)
        end
        error.message.should eq "PTP I/O Error\nAn error occurred in the io-library"
        context.last_error.should be_nil

        # Messages of the previous call don't leak into the next one
        LibGPhoto2.gp_context_error(context, "Another error")
        expect_raises(Context::Error) do
          context.check!(LibGPhoto2::GP_ERROR_IO)
        end.message.should eq "Another error"
        context.close
      end

      it "discards the last error message on success" do
        context = Context.new
        LibGPhoto2.gp_context_error(context, "Stale error")
        context.check!(LibGPhoto2::GP_OK)
        context.last_error.should be_nil

        error = expect_raises(GPhoto2::Error) do
          context.check!(LibGPhoto2::GP_ERROR_IO)
        end
        error.should_not be_a Context::Error
        error.message.should eq "I/O problem"
        context.close
      end

      it "raises a generic error when the last error message is blank" do
        context = Context.new
        LibGPhoto2.gp_context_error(context, " ")
        error = expect_raises(GPhoto2::Error, "I/O problem") do
          context.check!(LibGPhoto2::GP_ERROR_IO)
        end
        error.should_not be_a Context::Error
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
