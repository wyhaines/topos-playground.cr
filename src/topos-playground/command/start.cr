require "semantic_version"
require "../command"
require "../../ext/semantic_version"
require "../env/*"

class ToposPlayground::Command::Start < ToposPlayground::Command
  REDIS_CONTAINER_NAME = "redis-stack-server"

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
    copy_git_repositories_from_cache
    copy_env_files
    run_redis
    run_local_erc20_messaging_infra
    retrieve_and_write_contract_addresses_to_env
    run_executor_service
    run_dapp_frontend_service
    completion_banner
  end

  def verify_dependency_installation
    verify_docker_installation
    verify_docker_compose_installation
    verify_git_installation
  end

  def verify_docker_installation
    status, stdout, stderr = run_process("docker --version")
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
    status, stdout, stderr = run_process("docker compose version")
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
    status, stdout, stderr = run_process("git version")
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
      repo_path = File.join(config.cache_dir.to_s, repo[:repo])

      if Dir.exists?(repo_path)
        Log.for("stdout").info { "✅ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} already cloned" }
        update_repository(repo_path)
      else
        Log.for("stdout").info { "Cloning #{repo[:org]}/#{repo[:repo]}..." }
        status, stdout, stderr = run_process("git clone --depth 1 #{repo[:branch] ? "--branch #{repo[:branch]}" : ""} https://github.com/#{repo[:org]}/#{repo[:repo]}.git #{repo_path}")
        if status.success?
          Log.for("stdout").info { "✅ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} successfully cloned" }
          Fiber.yield
        else
          Log.for("stdout").info { "❌ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} failed to clone" }
        end
      end
    end
  rescue ex
    Error.error { "Failed to clone git repositories: #{ex.message}" }
    exit 1
  end

  def update_repository(repo_path)
    Log.for("stdout").info { "  Updating cached github repository: #{repo_path}" }
    status, stdout, stderr = run_process(
      "git pull",
      repo_path)

    if status.success?
      Log.for("stdout").info { "  ✅ Respository is up-to-date" }
    else
      Log.for("stdout").info { "  ❌ Repository update failed: #{stdout}\n#{stderr}" }
    end
  rescue ex
    Error.error { "Repository update failed: #{ex.message}" }
    exit 1
  end

  def copy_git_repositories_from_cache
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Copying git repositories from cache..." }
    GIT_REPOS.each do |repo|
      cache_path = File.join(config.cache_dir.to_s, repo[:repo])
      repo_path = File.join(config.working_dir.to_s, repo[:repo])
      FileUtils.rm_r(repo_path) if File.exists?(repo_path)
      FileUtils.cp_r(cache_path, repo_path)
      Log.for("stdout").info { "✅ Copied #{repo[:repo]}" }
    end
  end

  def copy_env_files
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Copying env files..." }
    Fiber.yield
    EnvRegistry.values.each do |env_class|
      env_file = env_class.new
      if content = env_file.content
        filename = sub_working_dir(env_file.path.to_s)
        if File.exists?(filename)
          Log.for("stdout").info { "✅ #{filename} already exists" }
        else
          File.open(filename, "w+") do |fh|
            fh.write content.to_slice
          end
          Log.for("stdout").info { "✅ #{filename} file successfully created" }
          Fiber.yield
        end
      end
    end
  rescue ex
    Error.error { "Failed to copy env files: #{ex.message}" }
    exit 1
  end

  def sub_working_dir(path)
    path.to_s.gsub(/WORKINGDIR/, config.working_dir.to_s)
  end

  def run_local_erc20_messaging_infra
    Fiber.yield
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Running the ERC20 messaging infrastructures..." }

    status, stdout, stderr = run_process(
      %(/bin/bash -c "source #{config.working_dir}/.env.secrets && docker compose up -d"),
      chdir: config.execution_path.to_s,
      env: EnvRegistry["secrets"].new.env)

    if status.success?
      Log.for("stdout").info { "✅ Subnets & TCE are running" }
    else
      Error.error { "#{status.exit_reason}: Failure while starting the subnets & TCE: #{stderr}" }
      exit status.exit_code
    end
  rescue ex
    Error.error { "Failed to start the subnets & TCE: #{ex.message}" }
  end

  def retrieve_and_write_contract_addresses_to_env
    Fiber.yield
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Retrieving contract addresses..." }
    status, stdout, stderr = run_process(
      "docker cp contracts-topos:/contracts/.env #{config.working_dir}/.env.addresses",
      env: EnvRegistry["secrets"].new.env
    )

    pp parse_contract_addresses_to_hash("#{config.working_dir}/.env.addresses")
  end

  def parse_contract_addresses_to_hash(filename)
    result = {} of String => String
    File.open(filename, "r") do |fh|
      fh.each_line do |line|
        matches = line.gsub(/export\s+/, "").split(/=/)
        result[matches[0]] = matches[1]
      end
    end

    result
  end

  def run_redis
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Running the redis server..." }
    command =
      "docker start #{REDIS_CONTAINER_NAME} || " +
        "docker run -d --name #{REDIS_CONTAINER_NAME} -p 6379:6379 redis/#{REDIS_CONTAINER_NAME}:latest"
    status, stdout, stderr = run_process(command)
    if status.success?
      Log.for("stdout").info { "✅ Redis server is running" }
    else
      Error.error { "#{status.exit_reason}: Failure while starting the redis server: #{[stdout, stderr].join("\n")}" }
      exit status.exit_code
    end
  rescue ex
    Error.error { "Failed to start the redis server: #{ex.message}" }
  end

  def run_executor_service
    Fiber.yield
  end

  def run_dapp_frontend_service
    Fiber.yield
  end

  def completion_banner
    Fiber.yield
    banner = <<-EBANNER

    🔥 Everything is done! 🔥

    🚀 Start sending ERC20 tokens across subnet by accessing the dApp Frontend at http://localhost:3001

    Ctrl/cmd-c will shut down the dApp Frontend and the Executor Service BUT will keep subnets and the TCE running (use the clean command to shut them down)

    Logs were written to #{config.log_file_path}
    EBANNER

    Log.for("stdout").info { banner }
  end
end
