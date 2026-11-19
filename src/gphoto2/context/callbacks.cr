require "./error"

module GPhoto2
  class Context
    alias Feedback = LibGPhoto2::GPContextFeedback

    # Provides callbacks for libgphoto2.
    module Callbacks
      macro set_callback(key, callback_type, args, public_setter = true, &block)
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
          # "box" it: we allocate memory and store the Proc there
          boxed_data = Box.box(callback)

          # We must save this in Crystal-land so the GC doesn't collect it (*)
          @{{ key.id }}_box = boxed_data

          # We pass a callback that doesn't form a closure, and pass the boxed_data as
          # the callback data
          LibGPhoto2.gp_context_set_{{ key.id }}_func self, ->({{ args.join(", ").id }}) {
            data_as_callback = Box(typeof(callback)).unbox(data)

            {{ block.body }}
          }, boxed_data
        end

        protected def unset_{{ key.id }}_callback
          LibGPhoto2.gp_context_set_{{ key.id }}_func self, nil, nil
          @{{ key.id }}_callback = nil
          @{{ key.id }}_box = nil
        end
      end

      set_callback :cancel, Proc(Bool), [context, data] do
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
      set_callback :error, Proc(String, Void), [context, message, data], public_setter: false do
        data_as_callback.call String.new(message)
      end

      # :nodoc:
      #
      # Holds the last error message, separately from the context, so that
      # the error callback doesn't need to reference the context itself.
      # Such a reference cycle would prevent the context from being
      # ever finalized (and freed) by the GC.
      class ErrorState
        property message : String?
      end

      @error_state = ErrorState.new

      # Returns the last error message reported by libgphoto2.
      def last_error : String?
        @error_state.message
      end

      def initialize
        self.error_callback = nil
      end

      # Sets *error* callback. Pass `nil` to remove it.
      #
      # NOTE: Error messages are tracked (see `#last_error`) regardless
      # of the callback being set.
      def error_callback=(callback : Proc(String, Void)?) : Nil
        state = @error_state
        set_error_callback do |message|
          state.message = message
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
      # Raised error is a `Context::Error` carrying the last error message
      # reported by libgphoto2 (if any), or a generic `GPhoto2::Error` otherwise.
      def check!(rc : Int32) : Int32
        Debug.log(rc, backtrace_offset: 1, progname: "gphoto2.cr")
        # Error message (if any) belongs to the call which returned *rc*,
        # so it must not leak into the subsequent calls.
        error_message, @error_state.message = @error_state.message, nil
        return rc if GPhoto2.check?(rc)

        original_error = GPhoto2::Error.from_code(rc)
        if error_message
          raise Error.new(error_message, rc, original_error)
        else
          raise original_error
        end
      end
    end
  end
end
