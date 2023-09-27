require "../command"

class ToposPlayground::Command::Version < ToposPlayground::Command
  def self.options(parser, config)
    parser.on("version", "Show topos-playground version (v#{ToposPlayground::VERSION})") do
      self.new(config).run
    end
  end

  def run
    puts "topos-playground version #{ToposPlayground::VERSION}"
    exit
  end
end
