# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class DatabaseGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_database_gems
        add_gem "pg"
        add_gem "pg_search"
      end

      def create_database_config
        template "config/database.yml.tt", "config/database.yml"
      end

      def create_pg_search_initializer
        template "config/initializers/pg_search.rb.tt", "config/initializers/pg_search.rb"
      end

      def create_pg_extensions_migration
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        template "db/migrate/create_pg_extensions.rb.tt", "db/migrate/#{timestamp}_create_pg_extensions.rb"
      end

      def ensure_postgres_tool_version
        tool_versions = ".tool-versions"
        path = File.join(destination_root, tool_versions)

        if File.exist?(path)
          inject_once(into: tool_versions, content: "postgres 18")
        else
          create_file(tool_versions, "postgres 18\n")
        end
      end
    end
  end
end
