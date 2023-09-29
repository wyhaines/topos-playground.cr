require "./registry"
require "./command"

class ToposPlayground
  # A subclass of `Registry` that maps command names to command classes.
  # All classes that inherit from `Command` are automatically registered.
  class CommandRegistry < Registry
    @@name_to_class_map = {} of String => Command.class
  end
end
