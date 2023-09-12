require "tput"
require "./topos-playground/*"

class ToposPlayground
  @@terminal_width = -1
  property config : ToposPlayground::Config = ToposPlayground::Config.new

  alias Error = ErrorLog

  def self.terminal_width
    @@terminal_width > -1 ? @@terminal_width : (@@terminal_width = Tput.new.screen.width || 80)
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
    sleep 0
  end
end

ToposPlayground.new.run
