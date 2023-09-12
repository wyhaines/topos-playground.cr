class OptionParser
  def to_s(io : IO) : Nil
    # Get the width of the screen so that text can be intelligently wrapped.

    if banner = @banner
      io << ToposPlayground.break_text(banner.to_s, ToposPlayground.terminal_width)
      io << '\n'
    end
    @flags.join io, '\n'
  end

  private def append_flag(flag, description)
    indent = " " * 31
    description = description.gsub("\n", "\n#{indent}")
    if flag.size >= 27
      @flags << "    #{flag}\n#{ToposPlayground.break_text(indent + description, ToposPlayground.terminal_width)}"
    else
      @flags << "    #{flag}#{ToposPlayground.break_text(indent + description, ToposPlayground.terminal_width)[4 + flag.size..]}"
    end
  end

  def separator(message = "")
    @flags << ToposPlayground.break_text(message.to_s, ToposPlayground.terminal_width)
  end
end
