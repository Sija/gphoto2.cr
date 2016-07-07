@[Link("libgphoto2")]
lib LibGPhoto2

  #
  # Enums
  #

  enum GPContextFeedback
    OK
    Cancel
  end

  #
  # Aliases
  #

  alias GPContextIdleFunc = GPContext*, Void* ->

  alias GPContextErrorFunc    = GPContext*, LibC::Char*, Void*, Void* ->
  alias GPContextStatusFunc   = GPContext*, LibC::Char*, Void*, Void* ->
  alias GPContextMessageFunc  = GPContext*, LibC::Char*, Void*, Void* ->

  alias GPContextQuestionFunc = GPContext*, LibC::Char*, Void*, Void* -> GPContextFeedback
  alias GPContextCancelFunc   = GPContext*, Void* -> GPContextFeedback

  alias GPContextProgressStartFunc  = GPContext*, LibC::Float, LibC::Char*, Void*, Void* -> LibC::UInt
  alias GPContextProgressUpdateFunc = GPContext*, LibC::Int, LibC::Float, Void* ->
  alias GPContextProgressStopFunc   = GPContext*, LibC::Int, Void* ->

  #
  # Structs
  #

  struct GPContext
    idle_func : GPContextIdleFunc
    idle_func_data : Void*

    progress_start_func : GPContextProgressStartFunc
    progress_update_func : GPContextProgressUpdateFunc
    progress_stop_func : GPContextProgressStopFunc
    progress_func_data : Void*

    error_func : GPContextErrorFunc
    error_func_data : Void*

    question_func : GPContextQuestionFunc
    question_func_data : Void*

    cancel_func : GPContextCancelFunc
    cancel_func_data : Void*

    status_func : GPContextStatusFunc
    status_func_data : Void*

    message_func : GPContextMessageFunc
    message_func_data : Void*

    ref_count : LibC::UInt
  end

  #
  # Functions
  #

  fun gp_context_new() : GPContext*
  fun gp_context_ref(context : GPContext*)
  fun gp_context_unref(context : GPContext*)

  fun gp_context_set_progress_funcs(context : GPContext*, start_func : GPContextProgressStartFunc, update_func : GPContextProgressUpdateFunc, stop_func : GPContextProgressStopFunc, data : Void*)
  fun gp_context_set_idle_func(context : GPContext*, func : GPContextIdleFunc, data : Void*)
  fun gp_context_set_error_func(context : GPContext*, func : GPContextErrorFunc, data : Void*)
  fun gp_context_set_status_func(context : GPContext*, func : GPContextStatusFunc, data : Void*)
  fun gp_context_set_question_func(context : GPContext*, func : GPContextQuestionFunc, data : Void*)
  fun gp_context_set_cancel_func(context : GPContext*, func : GPContextCancelFunc, data : Void*)
  fun gp_context_set_message_func(context : GPContext*, func : GPContextMessageFunc, data : Void*)

  fun gp_context_idle(context : GPContext*)
  fun gp_context_error(context : GPContext*, format : LibC::Char*)
  fun gp_context_status(context : GPContext*, format : LibC::Char*)
  fun gp_context_message(context : GPContext*, format : LibC::Char*)
  fun gp_context_question(context : GPContext*, format : LibC::Char*) : GPContextFeedback
  fun gp_context_cancel(context : GPContext*) : GPContextFeedback

  fun gp_context_progress_start(context : GPContext*, target : LibC::Float, format : LibC::Char*) : LibC::UInt
  fun gp_context_progress_update(context : GPContext*, id : LibC::UInt, current : LibC::Float)
  fun gp_context_progress_stop(context : GPContext*, id : LibC::UInt)

end
