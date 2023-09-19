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
    #        dispatcher: Log::AsyncDispatcher.new(2048)))
    log_config.bind(
      "error",
      :debug,
      Log::IOBackend.new(
        STDOUT,
        formatter: StderrConsoleFormat,
        dispatcher: Log::DirectDispatcher))
    #        dispatcher: Log::AsyncDispatcher.new(2048)))
  end

  def setup_console_logging
    Log.setup { |c| ToposPlayground.bind_console_logging(c) }
  end

  def setup_all_logging
    # Log.builder.bind "stdout", :debug, Log::IOBackend.new(get_log_file, dispatcher: Log::AsyncDispatcher.new(2048))
    # Log.builder.bind "error", :debug, Log::IOBackend.new(get_log_file, dispatcher: Log::AsyncDispatcher.new(2048))
  end
end
