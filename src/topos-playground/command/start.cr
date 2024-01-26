require "semantic_version"
require "../command"
require "../../ext/semantic_version"
require "../env/*"

class ToposPlayground::Command::Start < ToposPlayground::Command
  REDIS_CONTAINER_NAME = "redis-stack-server"

  NODEJS_VERSION_REGEXP = /v([0-9]+\.[0-9]+\.[0-9]+)/m
  MIN_VERSION_NODEJS    = SemanticVersion.parse("16.0.0")

  DOCKER_VERSION_REGEXP = /Docker version ([0-9]+\.[0-9]+\.[0-9]+)/m
  MIN_VERSION_DOCKER    = SemanticVersion.parse("17.06.0")

  DOCKER_COMPOSE_VERSION_REGEXP = /Docker Compose version v([0-9]+\.[0-9]+\.[0-9]+)/m
  MIN_VERSION_DOCKER_COMPOSE    = SemanticVersion.parse("2.0.0")

  GIT_VERSION_REGEXP = /git version ([0-9]+\.[0-9]+\.[0-9]+)/m
  MIN_VERSION_GIT    = SemanticVersion.parse("2.0.0")

  GIT_REPOS = {
    # INFRA_REF in the official version
    {
      org:    "topos-protocol",
      repo:   "local-erc20-messaging-infra",
      branch: "v2.3.2",
    },
    # FRONTEND_REF in the official version
    {
      org:    "topos-protocol",
      repo:   "dapp-frontend-erc20-messaging",
      branch: "v1.2.0",
    },
    # EXECUTOR_SERVICE_REF in the official version
    {
      org:    "topos-protocol",
      repo:   "executor-service",
      branch: "v1.1.0",
    },
  }

  def self.options(parser, config)
    parser.on("start", "Verify that all dependencies are installed, clone any needed repositories, setup the environment, and start all of the docker containers for the Playground") do
      config.command = "start"
    end
  end

  def self.levenshtein_options
    {
      "start" => {} of String => Array(String),
    }
  end

  def self.log_to_file?(config)
    true
  end

  def run
    background_processes = [] of Tuple(Channel(Bool), Channel(String), Process)

    Log.for("stdout").info { "Starting Topos-Playground...\n" }

    verify_dependency_installation
    if config.offline?
      validate_git_cache
    else
      clone_git_repositories
    end
    copy_git_repositories_from_cache
    copy_env_files
    run_redis
    run_local_erc20_messaging_infra
    retrieve_and_write_contract_addresses_to_env

    run_executor_service.tap do |background_process|
      setup_io_handlers_for_background_process(background_process)
      background_processes << background_process
    end

    run_dapp_frontend_service.tap do |background_process|
      setup_io_handlers_for_background_process(background_process)
      background_processes << background_process
    end

    completion_banner
    wait_for background_processes
  end

  def verify_dependency_installation
    verify_nodejs_installation
    verify_docker_installation
    verify_docker_compose_installation
    verify_git_installation
  end

  def verify_nodejs_installation
    version_check(
      command: "node --version",
      version: MIN_VERSION_NODEJS,
      version_regexp: NODEJS_VERSION_REGEXP,
      formal_label: "Node.js"
    )
  end

  def verify_docker_installation
    version_check(command: "docker --version",
      version: MIN_VERSION_DOCKER,
      version_regexp: DOCKER_VERSION_REGEXP,
      formal_label: "Docker")
  end

  def verify_docker_compose_installation
    version_check(
      command: "docker compose version",
      version: MIN_VERSION_DOCKER_COMPOSE,
      version_regexp: DOCKER_COMPOSE_VERSION_REGEXP,
      formal_label: "Docker Compose",
      inline_label: "docker-compose"
    )
  end

  def verify_git_installation
    version_check(
      command: "git version",
      version: MIN_VERSION_GIT,
      version_regexp: GIT_VERSION_REGEXP,
      formal_label: "Git"
    )
  end

  def version_check(
    command,
    version,
    version_regexp,
    formal_label,
    inline_label = nil
  )
    status, output = run_process(command)
    if status.success? && (match = output.to_s.match(version_regexp))
      if SemanticVersion.parse(match[1]) >= version
        Log.for("stdout").info { "✅ #{formal_label} -- Version: #{match[1]}" }
      else
        Log.for("stdout").info { "❌ #{formal_label} -- Version: #{match[1]}" }
        Error.error { "#{formal_label} #{match[1]} is not supported. Please upgrade #{formal_label} to #{version} or higher." }
        exit 1
      end
    else
      Log.for("stdout").info { "Failed to verify #{inline_label || formal_label} installation: #{output}" }
      exit 1
    end
  rescue ex
    Error.error { "Failed to verify #{inline_label || formal_label} installation: #{ex.message}" }
    exit 1
  end

  def validate_git_cache
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Validating git cache for offline use..." }
    GIT_REPOS.each do |repo|
      repo_path = File.join(config.cache_dir.to_s, repo[:repo])

      if Dir.exists?(repo_path)
        Log.for("stdout").info { "✅ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} is cached" }
      else
        Log.for("stdout").info { "❌ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} not found in cache" }
        Error.error { "Git cache is not valid. Please run the start command with an internet connection to download the git repositories." }
        exit 1
      end
    end
  end

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
        status, _ = run_process("git clone --depth 1 #{repo[:branch] ? "--branch #{repo[:branch]}" : ""} https://github.com/#{repo[:org]}/#{repo[:repo]}.git #{repo_path}")
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
    status, output = run_process(
      "git pull",
      repo_path)

    if status.success?
      Log.for("stdout").info { "✅ Respository is up-to-date" }
    else
      Log.for("stdout").info { "❌ Repository update failed: #{output}" }
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
    EnvRegistry.classes.each do |env_class|
      env_file = env_class.new
      if content = env_file.content
        filename = sub_working_dir(env_file.path.to_s)
        if File.exists?(filename)
          Log.for("stdout").info { "✅ #{filename} already exists" }
        else
          File.open(filename, "w+") do |file_handle|
            file_handle.write content.to_slice
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

  def shell
    ["bash", "zsh"].compact_map { |exe| Process.find_executable(exe) }[0]? || "/bin/bash"
  end

  def run_local_erc20_messaging_infra
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Running the ERC20 messaging infrastructures..." }

    status, output = run_process(
      %(#{shell} -c "source #{config.working_dir}/.env.secrets && docker compose up -d"),
      chdir: config.execution_path.to_s,
      env: EnvRegistry["secrets"].new.env)

    if status.success?
      Log.for("stdout").info { "✅ Subnets & TCE are running" }
    else
      Error.error { "#{status.exit_reason}: Failure while starting the subnets & TCE: #{output}" }
      exit status.exit_code
    end
  rescue ex
    Error.error { "Failed to start the subnets & TCE: #{ex.message}" }
  end

  def retrieve_and_write_contract_addresses_to_env
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Retrieving contract addresses..." }
    run_process(
      "docker cp contracts-topos:/contracts/.env #{config.working_dir}/.env.addresses",
      env: EnvRegistry["secrets"].new.env
    )

    env_hash = parse_contract_addresses_to_hash("#{config.working_dir}/.env.addresses")

    File.open(
      sub_working_dir(EnvRegistry["dappfrontend"].new.path),
      "a+") do |file_handle|
      file_handle.puts "VITE_SUBNET_REGISTRATOR_CONTRACT_ADDRESS=#{env_hash["SUBNET_REGISTRATOR_CONTRACT_ADDRESS"]}"
      file_handle.puts "VITE_TOPOS_CORE_PROXY_CONTRACT_ADDRESS=#{env_hash["TOPOS_CORE_PROXY_CONTRACT_ADDRESS"]}"
      file_handle.puts "VITE_ERC20_MESSAGING_CONTRACT_ADDRESS=#{env_hash["ERC20_MESSAGING_CONTRACT_ADDRESS"]}"
    end
    Log.for("stdout").info { "✅ Contract addresses successfully written to #{sub_working_dir(EnvRegistry["dappfrontend"].new.path)}" }

    File.open(
      sub_working_dir(EnvRegistry["executorservice"].new.path),
      "a+") do |file_handle|
      file_handle.puts "SUBNET_REGISTRATOR_CONTRACT_ADDRESS=#{env_hash["SUBNET_REGISTRATOR_CONTRACT_ADDRESS"]}"
      file_handle.puts "TOPOS_CORE_PROXY_CONTRACT_ADDRESS=#{env_hash["TOPOS_CORE_PROXY_CONTRACT_ADDRESS"]}"
    end
    Log.for("stdout").info { "✅ Contract addresses successfully written to #{sub_working_dir(EnvRegistry["executorservice"].new.path)}" }
  end

  def parse_contract_addresses_to_hash(filename)
    result = {} of String => String
    File.open(filename, "r") do |file_handle|
      file_handle.each_line do |line|
        next if line.strip.empty?
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
    status, output = run_process(command)
    if status.success?
      Log.for("stdout").info { "✅ Redis server is running" }
    else
      Error.error { "#{status.exit_reason}: Failure while starting the redis server: #{output}" }
      exit status.exit_code
    end
  rescue ex
    Error.error { "Failed to start the redis server: #{ex.message}" }
  end

  def do_npm_install(path)
    npm = Process.find_executable("npm") || "npm"

    status, output = run_process(
      "#{npm} install",
      chdir: path
    )

    if status.success?
      Log.for("stdout").info { "✅ Dependencies are installed" }
    else
      Error.error { "#{status.exit_reason}: Failed to install dependencies: #{output}" }
      exit status.exit_code
    end
  rescue ex
    Error.error { "Failed to install dependencies: #{ex.message}" }
  end

  def start_executor_service(secrets_path, executor_service_path) : Tuple(Channel(Bool), Channel(String), Process)
    npm = Process.find_executable("npm") || "npm"

    kill_channel, monitor_channel, process = run_process(
      %(#{shell} -c "source #{secrets_path} && #{npm} start"),
      chdir: executor_service_path,
      env: nil,
      background: true
    )

    Log.for("stdout").info { "✅ Executor Service is running" }

    {kill_channel, monitor_channel, process}
  end

  def run_executor_service
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Running the Executor Service..." }

    secrets_path = File.join(config.working_dir.to_s, ".env.secrets")
    executor_service_path = File.join(config.working_dir.to_s, "executor-service")

    do_npm_install(executor_service_path)
    start_executor_service(secrets_path, executor_service_path)
  end

  def build_dapp_frontend_service(secrets_path, dapp_frontend_service_path)
    npm = Process.find_executable("npm") || "npm"

    status, output = run_process(
      %(#{shell} -c "source #{secrets_path} && #{npm} run frontend:build"),
      chdir: dapp_frontend_service_path
    )

    if status.success?
      Log.for("stdout").info { "✅ dApp Frontend is built" }
    else
      Error.error { "#{status.exit_reason}: Failed to build dApp Frontend: #{output}" }
      exit status.exit_code
    end
  end

  def start_dapp_frontend_service(secrets_path, dapp_frontend_service_path) : Tuple(Channel(Bool), Channel(String), Process)
    npm = Process.find_executable("npm") || "npm"
    kill_channel, monitor_channel, process = run_process(
      %(#{shell} -c "source #{secrets_path} && #{npm} run backend:start"),
      chdir: dapp_frontend_service_path,
      background: true
    )

    Log.for("stdout").info { "✅ dApp Frontend is running" }

    {kill_channel, monitor_channel, process}
  end

  def run_dapp_frontend_service
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Running the dApp Frontend..." }

    secrets_path = File.join(config.working_dir.to_s, ".env.secrets")
    dapp_frontend_service_path = File.join(config.working_dir.to_s, "dapp-frontend-erc20-messaging")

    do_npm_install(dapp_frontend_service_path)
    build_dapp_frontend_service(secrets_path, dapp_frontend_service_path)
    start_dapp_frontend_service(secrets_path, dapp_frontend_service_path)
  end

  # Everything is done; display some final information to the user.
  def completion_banner
    banner = <<-EBANNER

    🔥 Everything is done! 🔥

    🚀 Start sending ERC20 tokens across subnets by accessing the dApp Frontend at http://localhost:3001

    Ctrl/cmd-c will shut down the dApp Frontend and the Executor Service BUT will keep subnets and the TCE running (use the clean command to shut them down)

    Logs were written to #{config.log_file_path}
    EBANNER

    Log.for("stdout").info { banner }
  end

  # Setup an `at_exit` handler to ensure that the started processes are cleaned up upon
  # `topos-playground` exiting. Also spawn a fiber to monitor the processes and print
  # any IO sent to the monitor channel.
  def setup_io_handlers_for_background_process(background_process)
    at_exit do
      kill_channel, _, process = background_process
      begin
        process.terminate
      rescue ex : RuntimeError
        # Ignore; the process may have already been terminated
      end
      kill_channel.send(true)
    end

    spawn do
      _, monitor_channel, process = background_process
      while !monitor_channel.closed? && !process.terminated?
        puts monitor_channel.receive
      end
    end
  end

  # Block, waiting for the watched processes to die. They may be killed manually,
  # or via the `at_exit` handler that was created when they were started, and which
  # is triggered by the `topos-playground` process exiting, such as when `ctrl-c` is
  # pressed.
  def wait_for(background_processes)
    # TODO: Have a command line flag so that the CLI _does not_ block on the
    # execution of the executor or the dapp frontend. Also add a cleanup
    # phase to reap any executor or dapp frontend that may be running

    background_processes.each do |background_process|
      kill_channel, _, process = background_process
      process.wait
      kill_channel.send(true) unless kill_channel.closed?
    end
  end
end
