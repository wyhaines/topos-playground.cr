require "log"
require "./config"
require "./command_registry"
require "./error_log"

class ToposPlayground
  abstract class Command
    alias Log = ::Log
    alias Error = ErrorLog

    macro inherited
      CommandRegistry.register self
    end

    property config : Config
    class_property config : Config = ToposPlayground::Config.new

    def initialize(config)
      @config = config
      @@config = config
    end

    def self.run_process(command, chdir = ".", background : Bool = false, env : Process::Env = nil)
      kill_channel = Channel(Bool).new
      monitor_channel = Channel(String).new(100)
      output = IO::Stapled.new(*IO.pipe)
      process = Process.new(
        command,
        chdir: chdir.to_s,
        output: output,
        error: output,
        env: env
      )

      spawn(name: "kill-monitor #{command}") do
        kill_channel.receive

        Log.for("stdout").warn { "Terminating #{command}" } if config.verbose

        process.terminate
      end

      spawn(name: "output-monitor #{command}") do
        while line = output.gets
          monitor_channel.send line if config.verbose
          break if process.terminated?
        end
      end

      {kill_channel, monitor_channel, process}
    end

    def self.run_process(command, chdir = ".", env : Process::Env = nil, shell : Bool = true)
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      status = Process.run(
        command,
        shell: shell,
        output: stdout,
        error: stderr,
        env: env,
        chdir: chdir.to_s)

      {status, stdout, stderr}
    end

    def run_process(command, chdir = ".", env : Process::Env = nil, shell : Bool = true)
      self.class.run_process(command, chdir, env)
    end

    def run_process(command, chdir = ".", background : Bool = false, env : Process::Env = nil)
      self.class.run_process(command, chdir, background, env)
    end
  end
end
