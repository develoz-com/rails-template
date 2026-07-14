# frozen_string_literal: true

require "yaml"

module Develoz
  class Manifest
    Entry = Struct.new(:name, :description)

    class << self
      def load
        manifest_path = File.expand_path("../../config/generators.yml", __dir__)
        yaml_content = File.read(manifest_path)
        YAML.safe_load(yaml_content) || {}
      end

      def for(options)
        manifest = load
        auto_include_pwa(options)
        entries = []

        manifest.each do |name, config|
          if config["always"]
            entries << Entry.new(name, config["description"])
          else
            requires = config["requires"] || []
            entries << Entry.new(name, config["description"]) if requires_met?(options, requires)
          end
        end

        entries
      end

      private

      def auto_include_pwa(options)
        options.instance_variable_set(:@pwa, true) if options.push? && !options.pwa?
      end

      def requires_met?(options, requires)
        requires.all? { |flag| options.public_send("#{flag}?") }
      end
    end
  end
end
