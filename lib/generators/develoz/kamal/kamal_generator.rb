# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class KamalGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      class_option :push, type: :boolean, default: false

      def add_kamal_gem
        add_gem "kamal", require: false, group: :development
      end

      def create_deploy_config
        template "deploy.yml.tt", "config/deploy.yml"
      end

      def create_production_dockerfile
        template "dockerfile_prod.tt", "Dockerfile.prod"
      end

      def create_kamal_secrets
        template "kamal_secrets.tt", ".kamal/secrets"
      end

      def create_postgres_accessory
        template "accessories_postgres.yml.tt", "config/accessories/postgres.yml"
      end

      def ensure_secrets_gitignored
        ensure_gitignore ".kamal/secrets"
      end

      def kamal_app_name
        ENV.fetch("KAMAL_APP_NAME", app_name)
      end

      def kamal_image
        ENV.fetch("KAMAL_IMAGE", kamal_app_name)
      end

      def kamal_registry
        ENV.fetch("KAMAL_REGISTRY", "")
      end

      def kamal_servers
        ENV.fetch("KAMAL_SERVERS", "")
      end

      def push_enabled?
        options[:push]
      end
    end
  end
end
