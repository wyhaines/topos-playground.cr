class ToposPlayground
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
