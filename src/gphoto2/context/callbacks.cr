require "./error"

module GPhoto2
  class Context
    alias Feedback = LibGPhoto2::GPContextFeedback

    # Provides callbacks for libgphoto2.
    module Callbacks
      macro set_callback(key, callback_type, args, public_setter = true, fallback = nil, &block)
        getter! {{ key.id }}_callback : {{ callback_type.id }}
        private getter {{ key.id }}_box : Pointer(Void)?

        {% if public_setter %}
          # Sets *{{ key.id }}* callback. Pass `nil` to remove it.
          #
          # See: [LibGPhoto2#gp_context_set_{{ key.id }}_func](http://www.gphoto.org/doc/api/gphoto2-context_8h.html)
          def {{ key.id }}_callback=(callback : {{ callback_type.id }}?) : Nil
            if callback
              set_{{ key.id }}_callback(&callback)
            else
              unset_{{ key.id }}_callback
            end
          end
        {% end %}

        # The callback for the user doesn't have a Void*
        protected def set_{{ key.id }}_callback(&callback : {{ callback_type.id }})
          # We save our callback for l8r use.
          @{{ key.id }}_callback = callback

          # Since Proc is a {Void*, Void*}, we can't turn that into a Void*, so we
          # "box" it: we allocate memory and store the Proc there (along with
          # the state, which can't be reached through the context itself)
          boxed_data = Box.box({callback, @callback_state})

          # We must save this in Crystal-land so the GC doesn't collect it (*)
          @{{ key.id }}_box = boxed_data

          # We pass a callback that doesn't form a closure, and pass the boxed_data as
          # the callback data
          LibGPhoto2.gp_context_set_{{ key.id }}_func self, ->({{ args.join(", ").id }}) {
            data_as_callback, state =
              Box(Tuple(typeof(callback), CallbackState)).unbox(data)

            begin
              {{ block.body }}
            rescue ex
              # Exceptions can't propagate through the C code calling us, so
              # they're stored and re-raised later on, from within `#check!`
              state.exception ||= ex
              {{ fallback }}
            end
          }, boxed_data
        end

        protected def unset_{{ key.id }}_callback
          LibGPhoto2.gp_context_set_{{ key.id }}_func self, nil, nil

          @{{ key.id }}_callback = nil
          @{{ key.id }}_box = nil
        end
      end

      # Cancels the operation if the callback raises.
      set_callback :cancel, Proc(Bool), [context, data], fallback: Feedback::Cancel do
        data_as_callback.call ? Feedback::Cancel : Feedback::OK
      end

      # ameba:disable Lint/VoidOutsideLib
      set_callback :idle, Proc(Void), [context, data] do
        data_as_callback.call
      end

      {% for key in %w(status message) %}
        set_callback {{ key.id }}, Proc(String, Void), [context, message, data] do
          data_as_callback.call String.new(message)
        end
      {% end %}

      # Public setter is defined below, since it needs to track the last error.
      set_callback :error, Proc(String, Void), [context, message, data], public_setter: false do # ameba:disable Lint/VoidOutsideLib
        data_as_callback.call String.new(message)
      end

      # :nodoc:
      #
      # Holds the error messages and the exception raised by a callback,
      # separately from the context, so that callbacks don't need to reference
      # the context itself. Such a reference cycle would prevent the context
      # from being ever finalized (and freed) by the GC.
      class CallbackState
        # Error messages reported (in order) during the current call, since
        # libgphoto2 might report several, i.e. the one of the camera driver,
        # followed by a generic one (see `#check!`).
        getter messages = [] of String
        property exception : ::Exception?
      end

      @callback_state = CallbackState.new

      # Returns the last error message reported by libgphoto2.
      def last_error : String?
        @callback_state.messages.last?
      end

      def initialize
        self.error_callback = nil
      end

      # Sets *error* callback. Pass `nil` to remove it.
      #
      # NOTE: Error messages are tracked (see `#last_error`) regardless
      # of the callback being set.
      def error_callback=(callback : Proc(String, Void)?) : Nil # ameba:disable Lint/VoidOutsideLib
        state = @callback_state
        set_error_callback do |message|
          state.messages << message
          callback.try &.call(message)
        end
        @error_callback = callback
      end

      # Clears all callbacks.
      def clear_callbacks : Nil
        {% for key in %w(cancel idle status message) %}
          unset_{{ key.id }}_callback if {{ key.id }}_callback?
        {% end %}
        self.error_callback = nil
      end

      # Returns the given return code *rc*, or raises if it's an error code.
      #
      # Raised error is a `Context::Error` carrying the error messages reported
      # by libgphoto2 during the call (if any), one per line, in the order they
      # were reported, or a generic `GPhoto2::Error` otherwise.
      #
      # Exception raised by any of the callbacks during the call which returned
      # *rc* takes precedence, and is re-raised regardless of *rc*.
      def check!(rc : Int32) : Int32
        Debug.log(rc, backtrace_offset: 1, progname: "gphoto2.cr")

        # Error messages (if any) belong to the call which returned *rc*,
        # so they must not leak into the subsequent calls.
        error_message = take_error_message
        if exception = @callback_state.exception
          @callback_state.exception = nil
          raise exception
        end
        return rc if GPhoto2.check?(rc)

        original_error = GPhoto2::Error.from_code(rc)
        if error_message
          raise Error.new(error_message, rc, original_error)
        else
          raise original_error
        end
      end

      # :nodoc:
      #
      # Same as `#check!`, but returns `false` (instead of raising) for the
      # error codes the block returns `true` for, or `true` on success.
      #
      # NOTE: Exceptions raised by any of the callbacks are re-raised
      # regardless, so these are never mistaken for the tolerated errors.
      def check?(rc : Int32, & : Int32 -> Bool) : Bool
        if !GPhoto2.check?(rc) && @callback_state.exception.nil? && yield rc
          Debug.log(rc, backtrace_offset: 1, progname: "gphoto2.cr")
          # The error messages belong to this call, see `#check!`
          take_error_message
          return false
        end
        check!(rc)
        true
      end

      # Returns the error messages reported during the current call (joined
      # into one), or `nil` if there are none, clearing them along the way.
      #
      # NOTE: The messages reported first are kept as well, since these tend
      # to be the most specific ones (i.e. the one of the camera driver),
      # while the following ones (i.e. reported by libgphoto2 itself on the
      # way out) are more generic.
      private def take_error_message : String?
        messages = @callback_state.messages
        return if messages.empty?

        # Blank messages carry no information, unlike the generic one
        message = messages.reject(&.blank?).join('\n').presence
        messages.clear
        message
      end
    end
  end
end
