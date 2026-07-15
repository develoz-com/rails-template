# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class CiGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_ci_gems
        add_gem "rubocop-rails-omakase", group: %i[development test]
        add_gem "reek", group: %i[development test]
        add_gem "flay", group: %i[development test]
        add_gem "brakeman", group: %i[development test]
        add_gem "bundler-audit", group: %i[development test]
        add_gem "haml_lint", require: false, group: %i[development test]
      end

      def create_ci_entrypoint
        template "bin/ci.tt", "bin/ci"
      end

      def create_ci_config
        template "config/ci.rb.tt", "config/ci.rb"
      end

      def create_rakefile
        template "Rakefile.tt", "Rakefile"
      end

      def create_rubocop_config
        template ".rubocop.yml.tt", ".rubocop.yml"
      end

      def create_reek_config
        template ".reek.yml.tt", ".reek.yml"
      end

      def create_biome_config
        template "biome.json.tt", "biome.json"
      end

      def create_stylelint_config
        template ".stylelintrc.json.tt", ".stylelintrc.json"
      end

      def create_haml_lint_config
        template ".haml-lint.yml.tt", ".haml-lint.yml"
      end

      def create_markdownlint_config
        template ".markdownlint.json.tt", ".markdownlint.json"
      end

      def create_yamllint_config
        template ".yamllint.tt", ".yamllint"
      end

      def create_ci_workflow
        template ".github/workflows/ci.yml.tt", ".github/workflows/ci.yml"
      end
    end
  end
end
