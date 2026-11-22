require "debug"

require "./lib/*"
require "./gphoto2/*"

{% if Debug::ACTIVE %}
  Debug.configure do |settings|
    settings.location_detection = :runtime
    settings.max_path_length = nil
  end

  if Debug.enabled?
    gp_log_level = GPhoto2::LogLevel.parse(ENV["LIB_LOG_LEVEL"]? || "debug")
    gp_logger =
      ->(level : LibGPhoto2::GPLogLevel, _domain : LibC::Char*, str : LibC::Char*, _data : Void*) {
        proc = ->(emitter : Log::Emitter) do
          emitter.emit(String.new(str), progname: "libgphoto2")
        end
        logger = Debug.logger
        case level
        in .error?         then logger.error &proc
        in .verbose?       then logger.notice &proc
        in .debug?, .data? then logger.debug &proc
        end
      }
    LibGPhoto2.gp_log_add_func(gp_log_level, gp_logger, nil)
  end
{% end %}

module GPhoto2
  extend self

  alias VersionVerbosity = LibGPhoto2::GPVersionVerbosity
  alias LogLevel = LibGPhoto2::GPLogLevel

  # Returns the GPhoto2 library version.
  #
  # With `:verbose` *verbosity*, the version is followed by the
  # (newline-separated) description of the library build features.
  #
  # ```
  # GPhoto2.library_version           # => "2.5.31"
  # GPhoto2.library_version(:verbose) # => "2.5.31\nall camlibs (...)\n..."
  # ```
  def library_version(verbosity : VersionVerbosity = :short) : String
    # Returned value is a `NULL`-terminated array of strings
    list = LibGPhoto2.gp_library_version(verbosity)
    return String.new(list.value) if verbosity.short?

    String.build do |io|
      while entry = list.value
        io << '\n' unless io.empty?
        io << String.new(entry)
        list += 1
      end
    end
  end

  # Returns the GPhoto2 return code (*rc*) as a string.
  def result_as_string(rc : Int32) : String
    String.new LibGPhoto2.gp_result_as_string(rc)
  end

  # :nodoc:
  #
  # Returns a `String` from the given fixed-size C *chars* array,
  # stopping at the first null byte or at the end of the array,
  # whichever comes first.
  def string_from(chars : StaticArray(LibC::Char, N)) : String forall N
    slice = chars.to_slice
    String.new(slice[0, slice.index(0_u8) || slice.size])
  end

  # :nodoc:
  #
  # Returns `Time` for the given Unix timestamp (in *seconds*), or `nil`
  # if it's out of the range supported by `Time` (i.e. year 1-9999),
  # since cameras might report bogus timestamps.
  def time_from(seconds : Int) : Time?
    Time.unix(seconds.to_i64)
  rescue ArgumentError | OverflowError
  end

  # :nodoc:
  #
  # Returns `true` if the given *string* represents the *number* numerically
  # (i.e. `"4"` or `"4.0"` for `4`).
  #
  # Integers are compared exactly, rather than through `Float64` (which would
  # make i.e. `"9007199254740992"` equal `9007199254740993`), while `Float32`
  # values are widened through their shortest decimal representation (see
  # `CameraWidget::Range#choices`), so that i.e. `0.3_f32` equals `"0.3"`.
  def number_string?(string : String, number : Number) : Bool
    if number.is_a?(Int)
      if integer = string.to_i128?
        return integer == number
      end
      # Integers beyond these can't be compared through `Float64` exactly
      return false unless -(2_i64 ** 53) <= number <= 2_i64 ** 53
    end
    float = number.is_a?(Float32) ? number.to_s.to_f64 : number.to_f64
    string.to_f64? == float
  end

  # :nodoc:
  #
  # Returns normalized, absolute posix version of the given *path*.
  def absolute_path(path : Path | String) : Path
    path = path.is_a?(String) ? Path.posix(path) : path.to_posix
    path = Path.posix("/", path) unless path.absolute?
    path.normalize
  end

  # :nodoc:
  #
  # Returns `true` if the given *path* points to a folder rather than
  # a file, judging by its form alone (i.e. it's empty, ends with `/`,
  # `.` or `..`), regardless of whether it exists.
  def folder_path?(path : Path | String) : Bool
    # Converted first, so that non-posix (i.e. Windows) paths
    # are checked the same way as `.absolute_path` resolves them
    path = Path.posix(path)
    path.to_s.ends_with?('/') || path.basename.in?("", ".", "..")
  end

  # Returns `true` if the given return code *rc* denotes a success
  # (`GP_OK` or a non-negative value), `false` if it's an error code.
  def check?(rc : Int32) : Bool
    rc >= LibGPhoto2::GP_OK
  end

  # Returns the given return code *rc*, or raises `Error`
  # if it's an error code (see `.check?`).
  def check!(rc : Int32) : Int32
    Debug.log(rc, backtrace_offset: 1, progname: "gphoto2.cr")
    if check?(rc)
      rc
    else
      raise Error.from_code(rc)
    end
  end
end
