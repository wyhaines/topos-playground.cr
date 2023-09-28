require "./command/*"

class ToposPlayground
  def self.command
    CommandRegistry.[config.command?]?
  end

  def dispatch
    if config.command?
      ToposPlayground.command.try &.new(config).run
    end
  end
end
