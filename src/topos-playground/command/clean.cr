require "../command"

class ToposPlayground::Command::Clean < ToposPlayground::Command
  def run
    Log.for("stdout").info { "Cleaning up Topos-Playground...\n" }

    verify_working_directory
    verify_execution_path
    shutdown_ERC20_messagine_protocol_infra
    shutdown_redis
    remove_working_directory
  end

  def verify_working_directory
    if File.exists?("#{config.working_dir}") && File.directory?("#{config.working_dir}") && File.writable?("#{config.working_dir}")
      if Dir["#{config.working_dir}/*"].empty?
        Log.for("stdout").info { "✅ Working directory (#{config.working_dir}) is empty" }
      else
        Log.for("stdout").info { "✅ Found working directory (#{config.working_dir})" }
      end
      config.working_dir_exists = true
    else
      if !File.exists?("#{config.working_dir}")
        Log.for("stdout").info { "✅ Working directory (#{config.working_dir}) does not exist. Perhaps it was already cleaned?" }
      elsif !File.directory?("#{config.working_dir}")
        Error.error { "Working directory (#{config.working_dir}) is not a directory. Can not continue!" }
        exit 1
      else # It must not be writeable.
        Error.error { "Working directory (#{config.working_dir}) is not writable. Please check permissions." }
        exit 1
      end
      config.working_dir_exists = false
    end
  end

  def verify_execution_path
    if File.exists?("#{config.execution_path}") && File.directory?("#{config.execution_path}") && File.readable?("#{config.execution_path}")
      if Dir["#{config.execution_path}/*"].empty?
        Log.for("stdout").info { "✅ Execution path (#{config.execution_path}) is empty\n" }
      else
        Log.for("stdout").info { "✅ Found execution path (#{config.execution_path})\n" }
      end
      config.execution_path_exists = true
    else
      if !File.exists?("#{config.execution_path}")
        Log.for("stdout").info { "✅ Execution path (#{config.execution_path}) does not exist. Can not shut down any running containers.\n" }
      elsif !File.directory?("#{config.execution_path}")
        Error.error { "Execution path (#{config.execution_path}) is not a directory. Can not continue!" }
        exit 1
      else # It must not be writeable.
        Error.error { "Execution path (#{config.execution_path}) is not writable. Please check permissions." }
        exit 1
      end
      config.execution_path_exists = false
    end
  end

  def shutdown_ERC20_messagine_protocol_infra
    if config.execution_path_exists
      Log.for("stdout").info { "Shutting down ERC20 messaging protocol infrastructure..." }
      shutdown_docker_compose
    else
      Log.for("stdout").info { "✅ ERC20 messaging infra is not running; subnets & TCE are down\n" }
    end
  end

  private def shutdown_docker_compose
    command = "docker compose down -v"
    status, output = run_process(
      command,
      config.execution_path.to_s)
    if status.success?
      Log.for("stdout").info { "✅ subnets & TCE are down" }
    else
      Error.error { "Failed to shut down ERC20 messaging protocol infrastructure: #{output}" }
      exit 1
    end
  rescue ex
    Error.error { "Failed to shut down ERC20 messaging protocol infrastructure (#{config.execution_path}): #{ex}" }
    exit 1
  end

  def shutdown_redis
    redis_container_name = "redis-stack-server"
    status, output = run_process("docker ps --format '{{.Names}}'")
    if status.success?
      if output.to_s.includes?(redis_container_name)
        Log.for("stdout").info { "Shutting down the redis container..." }
        command = "docker rm -f #{redis_container_name}"
        status, output = run_process(command)

        if status.success?
          Log.for("stdout").info { "✅ redis is down\n" }
        else
          Error.error { "Failed to shut down redis: #{output}\n" }
        end
      else
        Log.for("stdout").info { "✅ redis is not running\n" }
      end
    else
      Error.error { "Failed to identify the redis container: #{output}" }
    end
  rescue ex
    puts ex
    Error.error { "Failed to identify the redis container: #{ex}" }
    exit 1
  end

  def remove_working_directory
    if config.working_dir_exists?
      Log.for("stdout").info { "Cleaning up the working directory (#{config.working_dir})..." }
      status, output = run_process("rm -rf #{config.working_dir}")
      if status.success?
        Log.for("stdout").info { "✅ Working directory has been removed" }
      else
        Error.error { "Failed to clean up the working directory (#{config.working_dir}): #{output}" }
      end
    else
      Log.for("stdout").info { "✅ Working directory (#{config.working_dir}) does not exist" }
    end
  rescue ex
    Error.error { "XFailed to clean up the working directory (#{config.working_dir}): #{ex}" }
    exit 1
  end
end
