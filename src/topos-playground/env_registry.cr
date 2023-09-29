require "./registry"

class ToposPlayground
  # A registry for all of the classes used to build executable environments.
  # Any class that subclasses `Env` will be automatically registered.
  class EnvRegistry < Registry
    @@name_to_class_map = {} of String => ToposPlayground::Env.class
  end
end
