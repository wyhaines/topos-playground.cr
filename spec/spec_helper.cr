require "spec"
require "../src/topos-playground"

LOG_STDOUT = IO::Memory.new
LOG_ERROR  = IO::Memory.new

def setup_memory_logging
  # Change Log setup to play nicely with specs
  Log.setup do |log_config|
    log_config.bind(
      "stdout",
      :trace,
      Log::IOBackend.new(
        LOG_STDOUT,
        formatter: ToposPlayground::StdoutConsoleFormat,
        dispatcher: Log::DirectDispatcher))
    log_config.bind(
      "error",
      :debug,
      Log::IOBackend.new(
        LOG_ERROR,
        formatter: ToposPlayground::StderrConsoleFormat,
        dispatcher: Log::DirectDispatcher))
  end
end

def will_colorize
  "".colorize(:green).to_s == "\e[32m\e[0m" ? true : false
end

setup_memory_logging
