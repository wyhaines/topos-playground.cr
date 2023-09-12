require "./env_registry"

class ToposPlayground
  abstract struct Env
    macro inherited
      EnvRegistry.register self
    end

    abstract def content
    abstract def path
  end
end