require "colorize"
require "log"

class ToposPlayground
  struct StderrConsoleFormat < Log::StaticFormatter
    def run
      string ToposPlayground.break_text(
        String.build do |str|
          str << "❗"
          str << "#{@entry.severity.label.rjust(6)}: #{@entry.message}".colorize(:green).to_s
        end,
        ToposPlayground.terminal_width
      )
    end
  end

  struct StdoutConsoleFormat < Log::StaticFormatter
    def run
      string ToposPlayground.break_text(
        "    #{@entry.message.colorize(:green)}",
        ToposPlayground.terminal_width)
    end
  end
end
