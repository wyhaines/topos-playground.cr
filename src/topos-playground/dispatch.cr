require "./command/*"

class ToposPlayground
  def dispatch
    if config.command?
      CommandRegistry.get(config.command).new(config).run
    end
  end
end
