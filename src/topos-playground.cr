require "term-screen"
require "file_utils"
require "./topos-playground/*"

class Log::Builder
  def each_log(&)
    @logs.reject! { |_, log_ref| log_ref.value.nil? }

    @logs.each_value do |log_ref|
      log = log_ref.value
      yield log if log
    end
  end
end

class ToposPlayground
  @@terminal_width = -1
  # @@tput : Tput::Namespace::Size? = nil

  property config : ToposPlayground::Config = ToposPlayground::Config.new
  @@config : ToposPlayground::Config = ToposPlayground::Config.new

  alias Error = ErrorLog

  def self.config
    @@config
  end

  def self.terminal_width
    @@terminal_width > -1 ? @@terminal_width : (@@terminal_width = determine_terminal_width)
  end

  def self.determine_terminal_width
    Term::Screen.size[1]
    # if path = Process.find_executable("stty")
    #   begin
    #     stdout = `stty size`
    #     cols = stdout.to_s.split(/\s+/)[1]?.to_s.to_i
    #     return cols
    #   rescue ex
    #   end
    # end

    # if path = Process.find_executable("tput")
    #   begin
    #     stdout = `tput cols`
    #     pp stdout.to_s
    #     return stdout.to_s.chomp.to_i
    #   rescue ex
    #   end
    # end
  end

  def initialize
    setup_console_logging
    parse_command_line
    initialize_directories
    error_check
    setup_all_logging
  end

  def run
    dispatch
  end
end

ToposPlayground.new.run
