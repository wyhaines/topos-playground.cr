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

    def run(command, chdir = ".")
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      status = Process.run(
        command,
        shell: true,
        output: stdout,
        error: stderr,
        chdir: chdir.to_s)

      {status, stdout, stderr}
    end
  end
end
