class ToposPlayground
  class Registry
    @@lock = Mutex.new

    def self.[]=(name, klass)
      @@lock.synchronize do
        @@name_to_class_map[name] = klass
      end
    end

    def self.set(name, klass)
      self[name] = klass
    end

    def self.register(klass)
      @@lock.synchronize do
        @@name_to_class_map[klass.name.split(/::/).last.to_s.downcase] = klass
      end
    end

    def self.registry
      @@name_to_class_map
    end

    def self.[](key)
      @@name_to_class_map[key]
    end

    def self.[]?(key)
      @@name_to_class_map[key]?
    end

    def self.get(key)
      self[key]
    end

    def self.names
      @@name_to_class_map.keys
    end

    def self.classes
      @@name_to_class_map.values
    end
  end
end
