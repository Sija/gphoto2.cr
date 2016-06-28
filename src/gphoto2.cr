require "logger"

require "./ffi/*"
require "./gphoto2/*"

module GPhoto2
  @@logger : Logger?

  def self.result_as_string(rc : Int32)
    String.new FFI::LibGPhoto2.gp_result_as_string(rc)
  end

  def self.logger : Logger
    @@logger ||= begin
      logger = Logger.new(STDERR)
      logger.level = Logger::DEBUG if ENV["DEBUG"]?
      logger
    end
  end

  macro with_logger(*args, backtrace_offset = 1, &block)
    if ENV["DEBUG"]?
      caller_list = caller.dup
      while !caller_list.empty? && caller_list.first? !~ /caller:Array\(String\)/i
        caller_list.shift?
      end
      caller_list.shift {{backtrace_offset}}
      unless caller_list.empty?
        str = String.build do |str|
          str << caller_list.first
          {% if !args.empty? %}
            str << " -- " << "{{args}} = " << {{args}}
          {% end %}
        end
        logger.debug str
      end
    end
    {{block.body}}
  end

  def self.check!(rc : Int32) : Int32
    with_logger(rc, backtrace_offset: 2) do
      return rc if rc >= FFI::LibGPhoto2::GP_OK
      raise Error.new(result_as_string(rc), rc)
    end
  end
end
