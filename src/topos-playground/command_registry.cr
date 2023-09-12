require "./registry"
require "./command"

class ToposPlayground
  class CommandRegistry < Registry
    @@name_to_class_map = {} of String => Command.class
  end
end
