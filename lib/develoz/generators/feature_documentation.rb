# frozen_string_literal: true

require "erb"
require "fileutils"

module Develoz
  module Generators
    module FeatureDocumentationLifecycle
      def invoke_all
        super
        document_feature
      end

      def defer_feature_documentation!
        @feature_documentation_deferred = true
      end

      def feature_documentation_deferred?
        @feature_documentation_deferred == true
      end

      private

      def document_feature
        entry = Manifest.all.find { |candidate| candidate.name == feature_name }
        return unless entry

        documentation = FeatureDocumentation.new(self)
        documentation.render
        documentation.reconcile(entries: [entry], mode: :additive) unless feature_documentation_deferred?
      end

      def feature_name
        return self.class.feature_name if self.class.respond_to?(:feature_name)

        self.class.name.demodulize.delete_suffix("Generator").underscore
      end
    end

    class FeatureDocumentTemplate
      def initialize(generator, destination_root)
        @generator = generator
        @destination_root = destination_root
      end

      def render
        entry = Manifest.fetch(feature_name)
        source = File.join(generator.class.source_root, "docs/#{entry.documentation_slug}.md.tt")
        unless File.exist?(source)
          raise Develoz::Error, "Missing feature documentation template for #{entry.name}: #{source}"
        end

        write_document(entry, render_source(source))
      end

      private

      attr_reader :destination_root, :generator

      def feature_name
        return generator.class.feature_name if generator.class.respond_to?(:feature_name)

        generator.class.name.demodulize.delete_suffix("Generator").underscore
      end

      def render_source(source)
        binding_context = generator.instance_eval("binding", __FILE__, __LINE__)
        ERB.new(File.binread(source), trim_mode: "-").result(binding_context)
      end

      def write_document(entry, rendered)
        destination = File.join(destination_root, "docs/#{entry.documentation_slug}.md")
        if File.exist?(destination)
          return if File.binread(destination) == rendered

          relative_path = destination.delete_prefix("#{destination_root}/")
          raise Develoz::Error, "#{relative_path} already exists with different content"
        end

        FileUtils.mkdir_p(File.dirname(destination))
        File.binwrite(destination, rendered)
      end
    end

    class FeatureDocumentation
      BEGIN_MARKER = "<!-- BEGIN DEVELOZ FEATURE DOCUMENTATION -->"
      END_MARKER = "<!-- END DEVELOZ FEATURE DOCUMENTATION -->"
      MANAGED_FILES = %w[README.md AGENTS.md].freeze

      def self.reconcile(destination_root:, entries:, mode:)
        new(destination_root:).reconcile(entries:, mode:)
      end

      def initialize(generator = nil, destination_root: nil)
        @generator = generator
        @destination_root = destination_root || generator.destination_root
      end

      def render
        FeatureDocumentTemplate.new(generator, destination_root).render
      end

      def reconcile(entries:, mode:)
        validate_mode!(mode)
        files = MANAGED_FILES.index_with { |path| existing_or_scaffold(path) }
        transformed = files.to_h do |path, content|
          selected_entries = mode == :additive ? additive_entries(path, content, entries) : entries
          [path, reconcile_content(path, content, ordered(selected_entries))]
        end
        transformed.each { |path, content| File.binwrite(File.join(destination_root, path), content) }
      end

      private

      attr_reader :destination_root, :generator

      def validate_mode!(mode)
        return if %i[additive authoritative].include?(mode)

        raise ArgumentError, "Unknown feature documentation reconciliation mode: #{mode.inspect}"
      end

      def existing_or_scaffold(path)
        absolute_path = File.join(destination_root, path)
        return File.binread(absolute_path) if File.exist?(absolute_path)

        path == "README.md" ? "# #{File.basename(destination_root)}\n\n" : "# AGENTS.md\n\n"
      end

      def additive_entries(path, content, entries)
        slugs = managed_documentation_slugs(path, content)
        manifest_entries = Manifest.all
        reject_unknown_slugs!(path, slugs, manifest_entries)
        existing_entries = manifest_entries.select { |entry| slugs.include?(entry.documentation_slug) }
        existing_entries | entries
      end

      def managed_documentation_slugs(path, content)
        managed_block(path, content)&.scan(%r{\(docs/([^)]+)\.md\)})&.flatten || []
      end

      def reject_unknown_slugs!(path, slugs, manifest_entries)
        unknown_slugs = slugs - manifest_entries.map(&:documentation_slug)
        return if unknown_slugs.empty?

        links = unknown_slugs.map { |slug| "docs/#{slug}.md" }.join(", ")
        raise Develoz::Error, "#{path} has unknown feature documentation link: #{links}"
      end

      def ordered(entries)
        names = entries.map(&:name)
        Manifest.all.select { |entry| names.include?(entry.name) }
      end

      def reconcile_content(path, content, entries)
        bounds = marker_bounds(path, content)
        block = documentation_block(entries)
        return append_block(content, block) unless bounds

        content.byteslice(0, bounds.begin) + block + content.byteslice(bounds.end, content.bytesize - bounds.end).to_s
      end

      def append_block(content, block)
        separator = if content.empty? || content.end_with?("\n\n")
                      ""
                    elsif content.end_with?("\n")
                      "\n"
                    else
                      "\n\n"
                    end
        "#{content}#{separator}#{block}\n"
      end

      def marker_bounds(path, content)
        begin_positions = marker_positions(content, BEGIN_MARKER)
        end_positions = marker_positions(content, END_MARKER)
        return if begin_positions.empty? && end_positions.empty?

        valid = begin_positions.one? && end_positions.one? && begin_positions.first < end_positions.first
        raise Develoz::Error, "#{path} has malformed Develoz feature documentation markers" unless valid

        begin_positions.first...(end_positions.first + END_MARKER.bytesize)
      end

      def marker_positions(content, marker)
        positions = []
        offset = 0
        while (position = content.index(marker, offset))
          positions << position
          offset = position + marker.bytesize
        end
        positions
      end

      def managed_block(path, content)
        bounds = marker_bounds(path, content)
        content.byteslice(bounds) if bounds
      end

      def documentation_block(entries)
        links = entries.map do |entry|
          "- [#{entry.documentation_title}](docs/#{entry.documentation_slug}.md)"
        end
        ([BEGIN_MARKER, "## Feature Documentation", ""] + links + [END_MARKER]).join("\n")
      end
    end
  end
end
