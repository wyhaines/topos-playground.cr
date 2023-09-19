require "./env_registry"

class ToposPlayground
  abstract struct Env
    macro inherited
      EnvRegistry.register self
    end

    abstract def content
    abstract def path

    def env(env = ENV.dup)
      merge_env({} of String => String, env)
    end

    def merge_env(data, env)
      env.each do |key, value|
        env[key] = value
      end

      env
    end
  end
end
