require "log"
require "./console_format"

class ToposPlayground
  @@log_file = nil

  def get_log_file
    (@@log_file ||= File.new(config.log_file_path.as(String), "a+")).as(File)
  end

  private def bind_console_logging(log_config)
    log_config.bind(
      "stdout",
      :debug,
      Log::IOBackend.new(
        STDOUT,
        formatter: StdoutConsoleFormat))
    log_config.bind(
      "error",
      :error,
      Log::IOBackend.new(
        STDERR,
        formatter: StderrConsoleFormat))
  end

  def setup_console_logging
    Log.setup { |c| bind_console_logging(c) }
  end

  def setup_all_logging
    Log.builder.bind "*", :debug, Log::IOBackend.new(get_log_file, dispatcher: Log::AsyncDispatcher.new)
  end
end
