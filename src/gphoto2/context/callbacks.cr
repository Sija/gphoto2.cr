module GPhoto2
  class Context
    class Error < GPhoto2::Error
      def initialize(message, code = -1)
        super
      end
    end

    module Callbacks
      macro set_callback(key, callback_type, &block)
        getter! {{key.id}}_callback : {{callback_type.id}}?

        # See: [LibGPhoto2#gp_context_set_{{key.id}}_func](http://www.gphoto.org/doc/api/gphoto2-context_8h.html)
        def {{key.id}}_callback=(callback : {{callback_type.id}}?) : Void
          if callback
            set_{{key.id}}_callback(&callback)
          else
            unset_{{key.id}}_callback
          end
        end

        # The callback for the user doesn't have a Void*
        protected def set_{{key.id}}_callback(&callback : {{callback_type.id}})
          # We must save this in Crystal-land so the GC doesn't collect it (*)
          @{{key.id}}_callback = callback

          # Since Proc is a {Void*, Void*}, we can't turn that into a Void*, so we
          # "box" it: we allocate memory and store the Proc there
          boxed_data = Box.box(callback)

          # We pass a callback that doesn't form a closure, and pass the boxed_data as
          # the callback data
          # LibGPhoto2.gp_context_set_XXX_func(self, ->(...) {
          #   # Now we turn data back into the Proc, using Box.unbox
          #   data_as_callback = Box(typeof(callback)).unbox(data)
          #   # And finally invoke the user's callback
          #   data_as_callback.call(...)
          # }, boxed_data)

          {{block.body}}
        end

        protected def unset_{{key.id}}_callback
          LibGPhoto2.gp_context_set_{{key.id}}_func self, nil, nil
          @{{key.id}}_callback = nil
        end
      end

      set_callback :cancel, Proc(Bool) do
        LibGPhoto2.gp_context_set_cancel_func self, ->(context, data) {
          data_as_callback = Box(typeof(callback)).unbox(data)
          data_as_callback.call \
            ? LibGPhoto2::GPContextFeedback::Cancel
            : LibGPhoto2::GPContextFeedback::OK
        }, boxed_data
      end

      set_callback :idle, Proc(Void) do
        LibGPhoto2.gp_context_set_idle_func self, ->(context, data) {
          data_as_callback = Box(typeof(callback)).unbox(data)
          data_as_callback.call
        }, boxed_data
      end

      {% for key in %w(error status message) %}
        set_callback {{key.id}}, Proc(String, Void) do
          LibGPhoto2.gp_context_set_{{key.id}}_func self, ->(context, message, data) {
            data_as_callback = Box(typeof(callback)).unbox(data)
            data_as_callback.call(String.new(message))
          }, boxed_data
        end
      {% end %}

      def initialize
        set_error_callback do |message|
          raise Error.new message
        end
      end
    end
  end
end