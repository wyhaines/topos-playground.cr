require "./registry"

class ToposPlayground
  class EnvRegistry < Registry
    @@name_to_class_map = {} of String => ToposPlayground::Env.class
  end
end
