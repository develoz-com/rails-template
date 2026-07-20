# frozen_string_literal: true

require "yaml"

module Develoz
  class Manifest
    Entry = Data.define(:name, :description, :documentation_slug, :documentation_title)

    DOCUMENTATION_SLUG_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    class << self
      def load
        manifest_path = File.expand_path("../../config/generators.yml", __dir__)
        yaml_content = File.read(manifest_path)
        manifest = YAML.safe_load(yaml_content) || {}
        validate!(manifest)
        manifest
      end

      def all
        load.map { |name, config| build_entry(name, config) }
      end

      def fetch(name)
        all.find { |entry| entry.name == name.to_s } || raise(KeyError, "Unknown generator: #{name}")
      end

      def for(options)
        manifest = load
        auto_include_pwa(options)
        entries = []

        manifest.each do |name, config|
          if config["always"]
            entries << build_entry(name, config)
          else
            requires = config["requires"] || []
            entries << build_entry(name, config) if requires_met?(options, requires)
          end
        end

        entries
      end

      private

      def build_entry(name, config)
        Entry.new(
          name:,
          description: config["description"],
          documentation_slug: config["documentation_slug"],
          documentation_title: config["documentation_title"]
        )
      end

      def validate!(manifest)
        slugs = manifest.map do |name, config|
          validate_documentation_metadata!(name, config)
          config["documentation_slug"]
        end
        duplicate_slugs = slugs.tally.select { |_, count| count > 1 }.keys
        return if duplicate_slugs.empty?

        raise Develoz::Error, "Duplicate documentation slug(s): #{duplicate_slugs.join(', ')}"
      end

      def validate_documentation_metadata!(name, config)
        slug = config["documentation_slug"]
        title = config["documentation_title"]
        valid_slug = slug.is_a?(String) && slug.match?(DOCUMENTATION_SLUG_PATTERN)
        valid_title = title.is_a?(String) && title.match?(/\S/)
        return if valid_slug && valid_title

        raise Develoz::Error, "Generator #{name} must define a valid documentation_slug and documentation_title"
      end

      def auto_include_pwa(options)
        options.instance_variable_set(:@pwa, true) if options.push? && !options.pwa?
      end

      def requires_met?(options, requires)
        requires.all? { |flag| options.public_send("#{flag}?") }
      end
    end
  end
end
