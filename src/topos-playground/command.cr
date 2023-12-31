require "log"
require "./command_registry"
require "./error_log"

class ToposPlayground
  # All commands inherit from this class. It provides the expected logging constant
  # interfaces, handles registration with the command registry, and access to the
  # topos-playground configuration. It also provides a couple convenience `#run_process`
  # methods for running processes and capturing their output either synchronously or
  # asynchronously.
  abstract class Command
    alias Log = ::Log
    alias Error = ErrorLog

    # Register the command with the command registry. Any class that inherits from
    # this class will be automatically registered.
    macro inherited
      CommandRegistry.register self
    end

    property config : Config
    class_property config : Config = Config.new

    # This class method is called when the playground is setting up its command line parser.
    # Any subclass can implement this method to add its own command line flags.
    def self.options(parser, config)
    end

    # If no command matches, the playground will attempt to find a command that might have
    # been the intended command. Each `Command` subclass can subclass this class method in
    # order to return a list of possible commands to use in the levenshtein matching process.
    def self.levenshtein_options
      Hash(String, Hash(String, Array(String))).new
    end

    # For some commands, writing a physical log of execution isn't necessary. This class
    # method will be called on the command before the playground sets up the physical log,
    # and if it returns `false`, the physical log will not be created. Subclasses that
    # should log to a physical file should override this method to return `true`.
    def self.log_to_file?(config)
      false
    end

    def initialize(config)
      @config = config
      @@config = config
    end

    # All subclasses must implement `#run`, which is responsible for carrying out the
    # logic of the command.
    abstract def run

    # Convenience method for running a process and capturing its output. This method
    # runs the process asynchronously, spawning two threads. One monitors an instance of
    # `Channel(Bool)` and kills the process when it receives a message. This allows the
    # process to be gracefully terminated when the user presses `Ctrl-C`.
    #
    # The other thread monitors the output of the process, and passes it through the
    # `monitor_channel` if verbose logging has been requested via the command line flags.
    #
    # The method returns a tuple containing the `kill_channel`, `monitor_channel`, and
    # `process` objects.
    def self.run_process(command, chdir = ".", background : Bool = false, env : Process::Env = nil)
      kill_channel = Channel(Bool).new
      monitor_channel = Channel(String).new(100)
      output = IO::Stapled.new(*IO.pipe)
      process = Process.new(
        command,
        shell: true,
        chdir: chdir.to_s,
        output: output,
        error: output,
        env: env
      )

      spawn(name: "kill-monitor #{command}") do
        kill_channel.receive

        Log.for("stdout").warn { "Terminating #{command}" } if config.verbose?

        process.terminate
      end

      spawn(name: "output-monitor #{command}") do
        while line = output.gets
          monitor_channel.send line if config.verbose?
          break if process.terminated?
        end
      end

      {kill_channel, monitor_channel, process}
    end

    def self.run_process(command, chdir = ".", env : Process::Env = nil, shell : Bool = true)
      output = IO::Memory.new
      status = Process.run(
        command,
        shell: shell,
        output: output,
        error: output,
        env: env,
        chdir: chdir.to_s)

      {status, output}
    end

    def run_process(command, chdir = ".", env : Process::Env = nil, shell : Bool = true)
      self.class.run_process(command, chdir, env)
    end

    def run_process(command, chdir = ".", background : Bool = false, env : Process::Env = nil)
      self.class.run_process(command, chdir, background, env)
    end
  end
end
