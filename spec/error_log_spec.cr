require "./spec_helper"

describe ToposPlayground::ErrorLog do
  before_each do
    setup_memory_logging()
  end

  after_each do
    LOG_ERROR.clear
  end

  it "Error.* logging works" do
    ToposPlayground::Error.error { "Log error 1" }
    ToposPlayground::Error.warn { "Log warn 2" }
    ToposPlayground::Error.fatal { "Log fatal 3" }
    log = LOG_ERROR.rewind.gets_to_end

    if will_colorize
      log.should eq(
        "❗\e[32m ERROR: Log error 1\e[0m\n" +
        "❗\e[32m  WARN: Log warn 2\e[0m\n" +
        "❗\e[32m FATAL: Log fatal 3\e[0m\n"
      )
    else
      log.should eq(
        "❗ ERROR: Log error 1\n" +
        "❗  WARN: Log warn 2\n" +
        "❗ FATAL: Log fatal 3\n"
      )
    end
  end
end
