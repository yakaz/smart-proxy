require 'puppet/parser'

module Proxy::Puppet

  class PuppetClass

    class << self
      # scans a given directory and its sub directory for puppet classes
      # returns an array of PuppetClass objects.
      def scan_directory directory
        Dir.glob("#{directory}/*/manifests/**/*.pp").map do |manifest|
          scan_manifest File.read(manifest), manifest
        end.compact.flatten
      end

      def scan_manifest manifest, filename
        klasses = []
        # Get a Puppet Parser to parse the manifest source
        env = Puppet::Node::Environment.new
        parser = Puppet::Parser::Parser.new env
        ast = parser.parse manifest
        # Get the parsed representation of the top most objects
        hostclass = ast.instantiate ''
        hostclass.each do |klass|
          # Only look at classes
          if klass.type == :hostclass and klass.namespace != ''
            params = {}
            # Get parameters and eventual default values
            klass.arguments.each do |name, value|
              value = value.to_s unless value == nil
              params[name] = value
            end
            klasses << new(klass.namespace, params)
          end
        end
        klasses
      rescue => e
        puts "Error while parsing #{filename}: #{e}"
        klasses
      end

    end

    def initialize name, params
      @klass = name || raise("Must provide puppet class name")
      @params = params
    end

    def to_s
      self.module.nil? ? name : "#{self.module}::#{name}"
    end

    # returns module name (excluding of the class name)
    def module
      klass[0..(klass.index("::")-1)] if has_module?(klass)
    end

    # returns class name (excluding of the module name)
    def name
      has_module?(klass) ? klass[(klass.index("::")+2)..-1] : klass
    end

    attr_reader :params

    private
    attr_reader :klass

    def has_module?(klass)
      !!klass.index("::")
    end

  end
end

