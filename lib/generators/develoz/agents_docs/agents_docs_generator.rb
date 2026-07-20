# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class AgentsDocsGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_api_gems
        add_gem "faraday"
        add_gem "faraday-retry"
        add_gem "vcr", group: %i[test]
        add_gem "webmock", group: %i[test]
      end

      def create_agents_md
        destination = File.join(destination_root, "AGENTS.md")
        if File.exist?(destination)
          promote_minimal_agents_scaffold(destination)
          return
        end

        template "AGENTS.md.tt", "AGENTS.md"
      end

      def create_docs
        template "docs/development.md.tt", "docs/development.md"
        template "docs/testing.md.tt", "docs/testing.md"
        template "docs/performance.md.tt", "docs/performance.md"
      end

      def create_pr_template
        template ".github/pull_request_template.md.tt",
                 ".github/pull_request_template.md"
      end

      def create_vcr_support
        template "spec/support/vcr.rb.tt", "spec/support/vcr.rb"
      end

      def create_faraday_support
        template "spec/support/faraday.rb.tt", "spec/support/faraday.rb"
      end

      def create_example_api_spec
        template "spec/requests/example_api_spec.rb.tt",
                 "spec/requests/example_api_spec.rb"
        template "spec/cassettes/Example_API/fetches_data_from_an_external_API.yml.tt",
                 "spec/cassettes/Example_API/fetches_data_from_an_external_API.yml"
      end

      private

      def promote_minimal_agents_scaffold(destination)
        content = File.binread(destination)
        begin_marker = Regexp.escape(FeatureDocumentation::BEGIN_MARKER)
        end_marker = Regexp.escape(FeatureDocumentation::END_MARKER)
        match = content.match(/\A# AGENTS\.md\n\n(?<block>#{begin_marker}.*#{end_marker})\n\z/m)
        return unless match

        template_content = File.binread(File.join(self.class.source_root, "AGENTS.md.tt"))
        File.binwrite(destination, "#{template_content.chomp}\n\n#{match[:block]}\n")
      end
    end
  end
end
