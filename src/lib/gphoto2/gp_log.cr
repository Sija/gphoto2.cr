@[Link("libgphoto2")]
lib LibGPhoto2
  #
  # Enums
  #

  enum GPLogLevel
    Error
    Verbose
    Debug
  end

  #
  # Aliases
  #

  alias GPLogFunc = GPLogLevel, LibC::Char*, LibC::Char*, Void* ->

  #
  # Functions
  #

  fun gp_log_add_func(level : GPLogLevel, func : GPLogFunc, data : Void*) : LibC::Int
  fun gp_log_remove_func(id : LibC::Int) : LibC::Int

  fun gp_log(level : GPLogLevel, domain : LibC::Char*, format : LibC::Char*, ...)
  fun gp_logv(level : GPLogLevel, domain : LibC::Char*, format : LibC::Char*, args : Void*)

  fun gp_log_with_source_location(level : GPLogLevel, file : LibC::Char*, line : LibC::Int, func : LibC::Char*, format : LibC::Char*, ...)
  fun gp_log_data(domain : LibC::Char*, data : LibC::Char*, size : LibC::UInt, format : LibC::Char*, ...)
end
