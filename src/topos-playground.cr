require "term-screen"
require "file_utils"
require "config"
require "./topos-playground/*"

# class Log::Builder
#   def each_log(&)
#     @logs.reject! { |_, log_ref| log_ref.value.nil? }

#     @logs.each_value do |log_ref|
#       log = log_ref.value
#       yield log if log
#     end
#   end
# end

class ToposPlayground
  @@terminal_width = -1

  property config : Config = Config.new
  @@config : Config = Config.new

  alias Error = ErrorLog

  def self.config
    @@config
  end

  def self.terminal_width
    @@terminal_width > -1 ? @@terminal_width : (@@terminal_width = determine_terminal_width)
  end

  def self.terminal_width=(value)
    @@terminal_width = value
  end

  def self.determine_terminal_width
    Term::Screen.size[1]
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
