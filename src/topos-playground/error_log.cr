class ToposPlayground
  class ErrorLog
    ErrSentinel = ""

    def self.trace(&block : -> String)
      msg = block.call
      ::Log.for("error").trace { "#{ErrSentinel}#{msg}" }
    end

    def self.debug(&block : -> String)
      msg = block.call
      ::Log.for("error").debug { "#{ErrSentinel}#{msg}" }
    end

    def self.info(&block : -> String)
      msg = block.call
      ::Log.for("error").info { "#{ErrSentinel}#{msg}" }
    end

    def self.info(&block : -> String)
      msg = block.call
      ::Log.for("error").info { "#{ErrSentinel}#{msg}" }
    end

    def self.notice(&block : -> String)
      msg = block.call
      ::Log.for("error").notice { "#{ErrSentinel}#{msg}" }
    end

    def self.warn(&block : -> String)
      msg = block.call
      ::Log.for("error").warn { "#{ErrSentinel}#{msg}" }
    end

    def self.error(&block : -> String)
      msg = block.call
      ::Log.for("error").error { "#{ErrSentinel}#{msg}" }
    end

    def self.fatal(&block : -> String)
      msg = block.call
      ::Log.for("error").fatal { "#{ErrSentinel}#{msg}" }
    end
  end
end
