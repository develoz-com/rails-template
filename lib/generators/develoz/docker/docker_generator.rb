# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class DockerGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def create_docker_compose
        template "docker-compose.yml.tt", "docker-compose.yml"
      end

      def create_dockerfile_dev
        template "dockerfile_dev.tt", "Dockerfile.dev"
      end

      def create_bin_dev
        template "bin_dev.tt", "bin/dev"
        chmod "bin/dev", 0o755
      end

      def create_bin_setup
        template "bin_setup.tt", "bin/setup"
        chmod "bin/setup", 0o755
      end

      def create_bin_docker_entrypoint
        template "bin_docker_entrypoint.tt", "bin/docker-entrypoint"
        chmod "bin/docker-entrypoint", 0o755
      end

      def create_bin_run
        template "bin_run.tt", "bin/run"
        chmod "bin/run", 0o755
      end

      def wire_env
        append_env "POSTGRES_USER", "postgres"
        append_env "POSTGRES_PASSWORD", "postgres"
        append_env "POSTGRES_DB", "#{app_name}_development"
        append_env "DATABASE_URL", "postgres://postgres:postgres@postgres:5432/#{app_name}_development"
        append_env "SELENIUM_URL", "http://selenium:4444"
        append_env "MAILCATCHER_URL", "http://mailcatcher:1080"
      end

      def ensure_env_gitignored
        ensure_gitignore(".env")
      end
    end
  end
end
