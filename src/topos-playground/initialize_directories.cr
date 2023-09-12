require "csuuid"

class ToposPlayground
  def initialize_directories
    config.home = ENV["HOME"]? || "."
    config.data_home = ENV["XDG_DATA_HOME"]? || File.join(config.home.as(String), ".local", "share")
    config.state_home = ENV["XDG_STATE_HOME"]? || File.join(config.home.as(String), ".local", "state")

    config.working_dir = File.join(config.data_home.as(String), "topos-playground")
    config.log_dir = File.join(config.state_home.as(String), "topos-playground", "logs")
    config.log_file_path = File.join(config.log_dir.as(String), "log-#{CSUUID.new}.log")
    config.execution_path = File.join(config.working_dir.as(String), "local-erc20-messaging-infra")

    Dir.mkdir_p(config.working_dir.as(String)) rescue mkdir_error(config.working_dir)
    Dir.mkdir_p(config.log_dir.as(String)) rescue mkdir_error(config.log_dir)
  end

  private def mkdir_error(path)
    Error.error { "Could not create directory: #{path}" }
    Error.error { "Please check the path and permissions." }
    exit 1
  end
end
