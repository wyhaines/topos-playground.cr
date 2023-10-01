require "log"
require "./console_format"

class ToposPlayground
  @@log_file = nil

  def get_log_file
    (@@log_file ||= File.new(config.log_file_path.as(String), "a+")).as(File)
  end

  def self.bind_console_logging(log_config)
    log_config.bind(
      "stdout",
      :trace,
      Log::IOBackend.new(
        STDOUT,
        formatter: StdoutConsoleFormat,
        dispatcher: Log::DirectDispatcher))
    log_config.bind(
      "error",
      :debug,
      Log::IOBackend.new(
        STDOUT,
        formatter: StderrConsoleFormat,
        dispatcher: Log::DirectDispatcher))
  end

  def setup_console_logging
    Log.setup { |c| ToposPlayground.bind_console_logging(c) }
  end

  def setup_all_logging
    if ToposPlayground.config.quiet?
      Log.setup { |_| }
    end

    if ToposPlayground.command.try &.log_to_file?(config)
      Log.builder.bind(
        "stdout", :trace,
        Log::IOBackend.new(
          get_log_file,
          dispatcher: Log::DirectDispatcher))
      Log.builder.bind(
        "error",
        :debug,
        Log::IOBackend.new(
          get_log_file,
          dispatcher: Log::DirectDispatcher))
    end
  end
end
