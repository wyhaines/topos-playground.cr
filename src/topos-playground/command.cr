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

    def initialize(config)
      @config = config
    end

    def self.run_process(command, chdir = ".", background : Bool = false, env : Process::Env = nil)
      kill_channel = Channel(Bool).new
      process = Process.new(
        command,
        chdir: chdir.to_s,
        env: env
      )

      spawn(name: command) do
        kill_channel.receive

        process.terminate
      end

      {kill_channel, process}
    end

    def self.run_process(command, chdir = ".", env : Process::Env = nil)
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      status = Process.run(
        command,
        shell: true,
        output: stdout,
        error: stderr,
        env: env,
        chdir: chdir.to_s)

      {status, stdout, stderr}
    end

    def run_process(command, chdir = ".", env : Process::Env = nil)
      self.class.run_process(command, chdir, env)
    end

    def run_process(command, chdir = ".", background : Bool = false, env : Process::Env = nil)
      self.class.run_process(command, chdir, background, env)
    end
  end
end
