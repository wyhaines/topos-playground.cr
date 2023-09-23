class ToposPlayground
  # An instance of `Config` provides a `Hash(String, String | Int | Bool)` that is accessed
  # via method calls. The method names are the keys of the hash.
  #
  # For example:
  #
  # ```
  # config = Config.new
  #
  # config.verbose = true
  # pp config.verbose # => true
  # if config.quiet? # => false
  #   puts "be quiet"
  # else
  #   puts "don't be quiet" # => "don't be quiet"
  # end
  # ```
  #
  # The `#data` method will return the raw data hash.
  #
  # ```
  # pp config.data # => {"verbose" => true}
  # ```
  #
  class Config
    alias ConfigTypes = String | Int32 | Bool
    DATA = Hash(String, ConfigTypes).new

    def data
      DATA
    end

    macro method_missing(call)
      {% if call.name == "[]" %}
        DATA[{{ call.args[0].id }}]
      {% elsif call.name == "[]?" %}
        DATA[{{ call.args[0].id }}]?
      {% elsif call.name == "[]=" %}
        DATA[{{ call.args[0].id }}] = {{ call.args[1].id }}
      {% elsif call.name =~ /=/ %}
        DATA[{{ call.name[0..-2].stringify }}] = {{ call.args[0] }}
      {% elsif call.name =~ /\?$/ %}
        DATA[{{ call.name[0..-2].stringify }}]?
      {% else %}
        DATA[{{ call.name.stringify }}]
      {% end %}
    end
  end
end
