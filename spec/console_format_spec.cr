require "./spec_helper"

describe ToposPlayground::StderrConsoleFormat do
  before_each do
    ToposPlayground.terminal_width = 80
  end

  after_each do
    ToposPlayground.terminal_width = -1
  end

  it "formats a message as expected" do
    entry = Log::Entry.new(
      source: "test",
      severity: Log::Severity::Error,
      message: "This is a test message",
      data: Log::Metadata.empty,
      exception: RuntimeError.new("This is a test message")
    )

    io = IO::Memory.new
    formatter = ToposPlayground::StderrConsoleFormat.new(entry, io)
    formatter.run

    io.rewind.gets_to_end.should eq "❗\e[32m ERROR: This is a test message\e[0m"
  end
end

describe ToposPlayground::StdoutConsoleFormat do
  before_each do
    ToposPlayground.terminal_width = 80
  end

  after_each do
    ToposPlayground.terminal_width = -1
  end

  it "formats a short message as expected" do
    entry = Log::Entry.new(
      source: "test",
      severity: Log::Severity::Info,
      message: "This is a test message",
      data: Log::Metadata.empty,
      exception: RuntimeError.new("This is a test message")
    )

    io = IO::Memory.new
    formatter = ToposPlayground::StdoutConsoleFormat.new(entry, io)
    formatter.run

    io.rewind.gets_to_end.should eq "\e[32mThis is a test message\e[0m"
  end

  it "formats a long message as expected" do
    entry = Log::Entry.new(
      source: "test",
      severity: Log::Severity::Debug,
      message: "abcde fghijklmnop q rstu vwxyz. abc defghij klmnopq rstuvwxyz. abcdef ghi jklmnop qrst uvw xyz.",
      data: Log::Metadata.empty,
      exception: RuntimeError.new("abcde fghijklmnop q rstu vwxyz. abc defghij klmnopq rstuvwxyz. abcdef ghi jklmnop qrst uvw xyz.")
    )

    io = IO::Memory.new
    formatter = ToposPlayground::StdoutConsoleFormat.new(entry, io)
    formatter.run

    io.rewind.gets_to_end.should eq(
      "\e[32mabcde fghijklmnop q rstu vwxyz. abc defghij klmnopq rstuvwxyz. abcdef ghi \n" +
      "jklmnop qrst uvw xyz.\e[0m")
  end
end
