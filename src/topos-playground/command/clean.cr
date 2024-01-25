require "./stop"

class ToposPlayground::Command::Clean < ToposPlayground::Command::Stop
  def self.options(parser, config)
    parser.on("clean", "Shut down Playground docker containers, and clean up the working directory. This is the same as doing a 'stop', followed by deletion of the playground's working directory") do
      config.command = "clean"
      parser.on("--no-delete", "Do not delete the working directory") do
        config.do_not_delete_working_dir = true
      end
    end
  end

  def self.levenshtein_options
    {
      "clean" => {"--no-delete" => [] of String},
    }
  end

  def run
    Log.for("stdout").info { "Cleaning up Topos-Playground...\n" }

    verify_working_directory
    verify_execution_path
    shutdown_erc20_messagine_protocol_infra
    shutdown_redis
    remove_working_directory
    completion_banner
  end

  def remove_working_directory
    if config.working_dir_exists?
      Log.for("stdout").info { "Cleaning up the working directory (#{config.working_dir})..." }
      if config.do_not_delete_working_dir?
        Log.for("stdout").info { "✅ Per command-line flag, working directory has not been removed" }
      else
        status, output = run_process("rm -rf #{config.working_dir}")
        if status.success?
          Log.for("stdout").info { "✅ Working directory has been removed" }
        else
          Error.error { "Failed to clean up the working directory (#{config.working_dir}): #{output}" }
        end
      end
    else
      Log.for("stdout").info { "✅ Working directory (#{config.working_dir}) does not exist" }
    end
  rescue ex
    Error.error { "XFailed to clean up the working directory (#{config.working_dir}): #{ex}" }
    exit 1
  end

  def completion_banner
    banner = <<-EBANNER

    🔥 The Topos Playground is down 🔥

    ❗Important❗
    Before starting the Topos Playground again, you must reset your MetaMask Account Data for each subnet (both Topos and Incal) in order to reset the nonce count. Refer to "https://support.metamask.io/hc/en-us/articles/360015488891-How-to-clear-your-account-activity-reset-account" for more information.

    EBANNER

    Log.for("stdout").info { banner }
  end
end
