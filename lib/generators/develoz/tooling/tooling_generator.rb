# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class ToolingGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def create_vscode
        template "vscode/settings.json.tt",   ".vscode/settings.json"
        template "vscode/extensions.json.tt", ".vscode/extensions.json"
        template "vscode/tasks.json.tt",      ".vscode/tasks.json"
      end

      def create_env_files
        template "env.example.tt", ".env.example"
        create_file ".env", "" unless File.exist?(File.join(destination_root, ".env"))
        ensure_gitignore(".env")
      end

      def create_bin_run
        template "bin/run.tt", "bin/run"
        chmod "bin/run", 0o755
      end

      def create_constants
        template "constants.rb.tt", "config/initializers/constants.rb"
      end

      def add_dotenv
        add_gem "dotenv-rails", group: %i[development test]
      end
    end
  end
end
