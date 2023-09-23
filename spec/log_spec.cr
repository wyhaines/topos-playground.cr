require "./spec_helper"

describe "ToposPlayground Log Setup" do
  before_each do
    setup_memory_logging()
  end

  after_each do
    LOG_STDOUT.clear
    LOG_ERROR.clear
  end

  it "logs to 'stdout' are captured" do
    Log.for("stdout").info { "Log 1 to stdout" }
    log = LOG_STDOUT.rewind.gets_to_end

    log.should eq "\e[32mLog 1 to stdout\e[0m\n"
  end

  it "logs to 'error' are captured" do
    Log.for("error").error { "Log 1 to error" }
    log = LOG_ERROR.rewind.gets_to_end

    log.should eq "❗\e[32m ERROR: Log 1 to error\e[0m\n"
  end

  it "logs to 'stdout' are wrapped for terminal width" do
    ToposPlayground.terminal_width = 80
    Log.for("stdout").info { "abcde fghijklmnop q rstu vwxyz. abc defghij klmnopq rstuvwxyz. abcdef ghi jklmnop qrst uvw xyz." }
    log = LOG_STDOUT.rewind.gets_to_end

    log.should eq(
      "\e[32mabcde fghijklmnop q rstu vwxyz. abc defghij klmnopq rstuvwxyz. abcdef ghi \n" +
      "jklmnop qrst uvw xyz.\e[0m\n")
    ToposPlayground.terminal_width = -1
  end
end
