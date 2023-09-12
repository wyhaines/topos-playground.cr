require "option_parser"
require "../ext/option_parser"
require "./helptext"
require "./break_text"

class ToposPlayground
  def parse_command_line
    parser = OptionParser.new do |parser|
      parser.banner = "Usage: topos-playground [options] [command] [arguments]"
      parser.separator HelpText

      parser.separator
      parser.separator "Options:"
      parser.on("--version", "Show topos-playground version (v#{ToposPlayground::VERSION})") do
        do_version
        exit
      end

      parser.on("-v", "--verbose", "Show more information about the execution of a command") { config.verbose = true }
      parser.on("-q", "--quiet", "Show minimal onscreen information about the execution of a command") { config.quiet = true }
      parser.on("-n", "--no-log", "Do not write a log file") { config.no_log = true }
      parser.on("-h", "--help", "Display this help") do
        puts parser
        exit
      end

      parser.separator "\nCommands:"
      parser.on("clean", "Shut down Playground docker containers, and clean up the working directory") do
        config.command = "clean"
      end
      parser.on("start", "Verify that all dependencies are installed, clone any needed repositories, setup the environment, and start all of the docker containers for the Playground") do
        config.command = "start"
      end
      parser.on("version", "Show topos-playground version (v#{ToposPlayground::VERSION})") do
        do_version
        exit
      end
    end

    parser.parse
    unless config.command?
      puts parser
      exit
    end
  end

  def do_version
    puts "topos-playground version #{ToposPlayground::VERSION}"
  end
end
