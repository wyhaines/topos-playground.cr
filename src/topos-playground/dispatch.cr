require "./command/*"

class ToposPlayground
  def dispatch
    CommandRegistry.get(config.command).new(config).run
  end
end
