require "option_parser"
require "defined"
require "levenshtein"
require "../ext/option_parser"
require "./helptext"
require "./break_text"

class ToposPlayground
  def parse_command_line
    parser = setup_options_parser

    parser.parse

    # When ran without arguments, it will print help, UNLESS it is being ran
    # when the `Spec` module is defined. This prevents the help from appearing
    # during spec runs.
    unless_defined?(Spec) do
      unless config.command?
        puts parser
        exit
      end
    end

    @@config = @config
  end

  private def setup_options_parser
    OptionParser.new do |parser|
      setup_options_helptext(parser)
      setup_options_general(parser)
      setup_options_commands(parser)
      setup_invalid_option(parser)
      setup_unknown_args(parser)
    end
  end

  private def setup_options_helptext(parser)
    parser.banner = "Usage: topos-playground [options] [command] [arguments]"
    parser.separator HelpText
    parser.separator
  end

  private def setup_options_general(parser)
    parser.separator "Options:"
    parser.on("--version", "Show topos-playground version (v#{ToposPlayground::VERSION})") do
      # do_version
      # exit
      Command::Version.new(config).run
    end

    parser.on("-v", "--verbose", "Show more information about the execution of a command") { config.verbose = true }
    parser.on("-q", "--quiet", "Show minimal onscreen information about the execution of a command") { config.quiet = true }
    parser.on("-nc", "--no-cache", "Don't use the cached git repositories") { config.no_cache = true }
    parser.on("-n", "--no-log", "Do not write a log file") { config.no_log = true }
    parser.on("-o", "--offline", "Depend on local git repository cache; don't perform any updates that require internet access") { config.offline = true }
    parser.on("-h", "--help", "Display help; this can be used with subcommands to get context-specific help") do
      puts parser
      exit
    end
  end

  private def base_levenshtein_options
    {
      "--version"  => {} of String => Array(String),
      "-v"         => {} of String => Array(String),
      "--verbose"  => {} of String => Array(String),
      "-q"         => {} of String => Array(String),
      "--quiet"    => {} of String => Array(String),
      "-nc"        => {} of String => Array(String),
      "--no-cache" => {} of String => Array(String),
      "-n"         => {} of String => Array(String),
      "--no-log"   => {} of String => Array(String),
      "-o"         => {} of String => Array(String),
      "--offline"  => {} of String => Array(String),
      "-h"         => {} of String => Array(String),
      "--help"     => {} of String => Array(String),
    }
  end

  private def setup_options_commands(parser)
    parser.separator "\nCommands:"
    CommandRegistry.names.sort.each do |command|
      CommandRegistry[command].options(parser, config)
    end
  end

  private def setup_invalid_option(parser)
    parser.invalid_option do |flag|
      error_text = <<-EERROR
      ERROR: '#{flag}' is not a valid option for topos-playground.

      Please check your command line, and if you have a question about the valid command line arguments, use `topos-playground --help` to see more complete instructions.

      EERROR

      STDERR.puts ToposPlayground.break_text(
        error_text,
        ToposPlayground.terminal_width
      )
      exit 1
    end
  end

  private def setup_unknown_args(parser)
    parser.unknown_args do |args|
      unless args.empty?
        arg = args.first
        suggestion = if config.command?
                       if config.subcommand?
                         levenshtein_for(config.command.to_s, config.subcommand.to_s, arg)
                       else
                         levenshtein_for(config.command.to_s, arg)
                       end
                     else
                       levenshtein_for(arg)
                     end

        if suggestion
          error_text = <<-EERROR
          ERROR: '#{arg}' is not a valid argument for topos-playground. Perhaps you meant to use '#{suggestion}'?

          EERROR

          STDERR.puts ToposPlayground.break_text(
            error_text,
            ToposPlayground.terminal_width
          )
          exit 1
        end
      end
    end
  end

  private def levenshtein_for(command, subcommand = nil, arg = nil)
    command = "logs" if command == "log"
    if subcommand.nil?
      possibilities = base_levenshtein_options
      CommandRegistry.names.each do |name|
        possibilities[name] = {} of String => Array(String)
      end
    else
      possibilities = CommandRegistry[command].levenshtein_options.merge(base_levenshtein_options)
    end

    command = "log" if command == "logs"

    if arg
      Levenshtein.find(arg, possibilities[command][subcommand].concat(base_levenshtein_options.keys))
    elsif subcommand
      Levenshtein.find(subcommand, possibilities[command].keys.concat(base_levenshtein_options.keys))
    else
      Levenshtein.find(command, possibilities.keys.concat(base_levenshtein_options.keys))
    end
  end
end
