require "./error"

module GPhoto2
  class Context
    alias Feedback = LibGPhoto2::GPContextFeedback

    module Callbacks
      macro set_callback(key, callback_type, args, &block)
        getter! {{ key.id }}_callback : {{ callback_type.id }}
        private getter {{ key.id }}_box : Pointer(Void)?

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

      set_callback :idle, Proc(Void), [context, data] do
        data_as_callback.call
      end

      {% for key in %w(error status message) %}
        set_callback {{ key.id }}, Proc(String, Void), [context, message, data] do
          data_as_callback.call String.new(message)
        end
      {% end %}

      getter last_error : String?

      def initialize
        set_error_callback do |message|
          @last_error = message
        end
      end

      def clear_callbacks : Nil
        {% for key in %w(cancel idle error status message) %}
          unset_{{ key.id }}_callback if {{ key.id }}_callback?
        {% end %}
      end

      def check!(rc : Int32) : Int32
        Debug.log(rc, backtrace_offset: 1, progname: "gphoto2.cr")
        return rc if GPhoto2.check?(rc)

        original_error = GPhoto2::Error.from_code(rc)
        if error_message = @last_error
          @last_error = nil
          raise Error.new(error_message, rc, original_error)
        else
          raise original_error
        end
      end
    end
  end
end
