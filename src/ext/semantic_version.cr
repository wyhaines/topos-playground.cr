struct SemanticVersion
  def self.parse(str : String) : self
    if m = str.match /^([0-9]\d*)\.([0-9]\d*)\.([0-9]\d*)
                      (?:-((?:[0-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:[0-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?
                      (?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/x
      major = m[1].to_i
      minor = m[2].to_i
      patch = m[3].to_i
      prerelease = m[4]?
      build = m[5]?
      new major, minor, patch, prerelease, build
    else
      raise ArgumentError.new("Not a semantic version: #{str.inspect}")
    end
  end
end
