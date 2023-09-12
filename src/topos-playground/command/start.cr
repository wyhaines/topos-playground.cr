require "semantic_version"
require "../command"
require "../../ext/semantic_version"
require "../env/*"

class ToposPlayground::Command::Start < ToposPlayground::Command
  DOCKER_VERSION_REGEXP = /Docker version ([0-9]+\.[0-9]+\.[0-9]+)/m
  MIN_VERSION_DOCKER    = SemanticVersion.parse("17.06.0")

  DOCKER_COMPOSE_VERSION_REGEXP = /Docker Compose version v([0-9]+\.[0-9]+\.[0-9]+)/m
  MIN_VERSION_DOCKER_COMPOSE    = SemanticVersion.parse("2.0.0")

  GIT_VERSION_REGEXP = /git version ([0-9]+\.[0-9]+\.[0-9]+)/m
  MIN_VERSION_GIT    = SemanticVersion.parse("2.0.0")

  GIT_REPOS = {
    {
      org:    "topos-protocol",
      repo:   "local-erc20-messaging-infra",
      branch: "v0.1.6",
    },
    {
      org:    "topos-protocol",
      repo:   "dapp-frontend-erc20-messaging",
      branch: "v0.1.4",
    },
    {
      org:    "topos-protocol",
      repo:   "executor-service",
      branch: "v0.2.0",
    },
  }

  def run
    Log.for("stdout").info { "Starting Topos-Playground...\n" }

    verify_dependency_installation
    clone_git_repositories
    copy_env_files
    run_local_erc20_messaging_infra
    retrieve_and_write_contract_addresses_to_env
    run_redis
    run_executor_service
    run_dapp_frontend_service
  end

  def verify_dependency_installation
    verify_docker_installation
    verify_docker_compose_installation
    verify_git_installation
  end

  def verify_docker_installation
    status, stdout, stderr = run("docker --version")
    if status.success? && (match = stdout.to_s.match(DOCKER_VERSION_REGEXP))
      if SemanticVersion.parse(match[1]) >= MIN_VERSION_DOCKER
        Log.for("stdout").info { "✅ Docker -- Version: #{match[1]}" }
      else
        Log.for("stdout").info { "❌ Docker -- Version: #{match[1]}" }
        Error.error { "Docker #{match[1]} is not supported. Please upgrade Docker to #{MIN_VERSION_DOCKER} or higher." }
        exit 1
      end
    else
      Log.for("stdout").info { "Failed to verify docker installation: #{stdout}#{stderr}" }
    end
  rescue ex
    Error.error { "Failed to verify docker installation: #{ex.message}" }
    exit 1
  end

  def verify_docker_compose_installation
    status, stdout, stderr = run("docker compose version")
    if status.success? && (match = stdout.to_s.match(DOCKER_COMPOSE_VERSION_REGEXP))
      if SemanticVersion.parse(match[1]) >= MIN_VERSION_DOCKER_COMPOSE
        Log.for("stdout").info { "✅ Docker Compose -- Version: #{match[1]}" }
      else
        Log.for("stdout").info { "❌ Docker Compose -- Version: #{match[1]}" }
        Error.error { "Docker Compose #{match[1]} is not supported. Please upgrade Docker Compose to #{MIN_VERSION_DOCKER_COMPOSE} or higher." }
        exit 1
      end
    else
      Log.for("stdout").info { "Failed to verify docker-compose installation: #{stdout}#{stderr}" }
    end
  rescue ex
    Error.error { "Failed to verify docker-compose installation: #{ex.message}" }
    exit 1
  end

  def verify_git_installation
    status, stdout, stderr = run("git version")
    if status.success? && (match = stdout.to_s.match(GIT_VERSION_REGEXP))
      if SemanticVersion.parse(match[1]) >= MIN_VERSION_GIT
        Log.for("stdout").info { "✅ Git -- Version: #{match[1]}" }
      else
        Log.for("stdout").info { "❌ Git -- Version: #{match[1]}" }
        Error.error { "Git #{match[1]} is not supported. Please upgrade Git to #{MIN_VERSION_GIT} or higher." }
        exit 1
      end
    else
      Log.for("stdout").info { "Failed to verify git installation: #{stdout}#{stderr}" }
    end
  rescue ex
    Error.error { "Failed to verify git installation: #{ex.message}" }
    exit 1
  end

  # TODO: If a cache for the github repos is implemented, then the tool could spin up a local devnet without requiring an internet connection.
  def clone_git_repositories
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Cloning git repositories..." }
    GIT_REPOS.each do |repo|
      repo_path = File.join(config.working_dir.to_s, repo[:repo])

      if Dir.exists?(repo_path)
        Log.for("stdout").info { "✅ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} already cloned" }
      else
        Log.for("stdout").info { "Cloning #{repo[:org]}/#{repo[:repo]}..." }
        status, stdout, stderr = run("git clone --depth 1 #{repo[:branch] ? "--branch #{repo[:branch]}" : ""} https://github.com/#{repo[:org]}/#{repo[:repo]}.git #{repo_path}")
        if status.success?
          Log.for("stdout").info { "✅ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} successfully cloned" }
        else
          Log.for("stdout").info { "❌ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} failed to clone: #{stderr}" }
        end
      end
    end
  rescue ex
    Error.error { "Failed to clone git repositories: #{ex.message}" }
    exit 1
  end

  def copy_env_files
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Copying env files..." }
    EnvRegistry.values.each do |env_class|
      env_file = env_class.new
      filename = sub_working_dir(env_file.path)
      if File.exists?(filename)
        Log.for("stdout").info { "✅ #{filename} already exists" }
      else
        File.open(filename, "w+") do |fh|
          fh.write env_file.content.to_slice
        end
        Log.for("stdout").info { "✅ #{filename} file successfully created" }
      end
    end
  end

  def sub_working_dir(path)
    path.gsub(/WORKINGDIR/, config.working_dir.to_s)
  end

  def run_local_erc20_messaging_infra
  end

  def retrieve_and_write_contract_addresses_to_env
  end

  def run_redis
  end

  def run_executor_service
  end

  def run_dapp_frontend_service
  end
end
