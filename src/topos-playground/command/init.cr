require "semantic_version"
require "../command"
require "../../ext/semantic_version"
require "../env/*"

class ToposPlayground::Command::Init < ToposPlayground::Command
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
      branch: "v2.5.0",
    },
    # FRONTEND_REF in the official version
    {
      org:    "topos-protocol",
      repo:   "dapp-frontend-erc20-messaging",
      branch: "v1.3.0",
    },
    # EXECUTOR_SERVICE_REF in the official version
    {
      org:    "topos-protocol",
      repo:   "executor-service",
      branch: "v1.2.0",
    },
  }

  def self.options(parser, config)
    parser.on("init", "Verify that all dependencies are installed, clone any needed repositories, and set up the environment in preparation for starting the playground nodes and instances.") do
      config.command = "init"
    end
  end

  def self.levenshtein_options
    {
      "init" => {} of String => Array(String),
    }
  end

  def self.log_to_file?(config)
    true
  end

  def run
    Log.for("stdout").info { "Initializing the Topos-Playground...\n" }

    verify_dependency_installation
    if config.offline?
      validate_git_cache
    else
      clone_git_repositories
    end
    copy_git_repositories_from_cache
    copy_env_files

    completion_banner
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

  def git_tag_matches?(repo_path, branch)
    status, output = run_process("git describe --tags --exact-match", repo_path)
    if status.success?
      return output.to_s.strip == branch
    end

    status, output = run_process("git rev-parse --abbrev-ref HEAD", repo_path)
    if status.success?
      return output.to_s.strip == branch
    end

    false
  end

  def validate_git_cache
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Validating git cache for offline use..." }
    GIT_REPOS.each do |repo|
      repo_path = File.join(config.cache_dir.to_s, repo[:repo])

      if Dir.exists?(repo_path) && git_tag_matches?(repo_path, repo[:branch])
        Log.for("stdout").info { "✅ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} is cached" }
      else
        Log.for("stdout").info { "❌ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} not found in cache" }
        Error.error { "Git cache is not valid. Please run the `topos-playground init` command with an internet connection to download the git repositories." }
        exit 1
      end
    end
  end

  def clone_git_repositories
    Log.for("stdout").info { "" }
    Log.for("stdout").info { "Cloning git repositories..." }
    GIT_REPOS.each do |repo|
      repo_path = File.join(config.cache_dir.to_s, repo[:repo])

      if Dir.exists?(repo_path) && git_tag_matches?(repo_path, repo[:branch])
        Log.for("stdout").info { "✅ #{repo[:repo]}#{repo[:branch] ? " | #{repo[:branch]}" : ""} already cloned" }
        update_repository(repo_path)
      else
        Log.for("stdout").info { "Cloning #{repo[:org]}/#{repo[:repo]}..." }
        _, _ = run_process("rm -rf #{repo_path}")
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

  # Everything is done; display some final information to the user.
  def completion_banner
    banner = <<-EBANNER

    🔥 Topos Playground is Initialized! 🔥

    Run `topos-playground start` to start the playground instances.

    Logs were written to #{config.log_file_path}
    EBANNER

    Log.for("stdout").info { banner }
  end
end
