# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class DbBackupGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      class_option :docker, type: :boolean, default: false

      def create_backup_script
        template "bin_db_backup.tt", "bin/db-backup"
        chmod "bin/db-backup", 0o755
      end

      def create_backup_rake
        template "backup_rake.tt", "lib/tasks/backup.rake"
      end

      def inject_compose_service
        return unless options[:docker]

        inject_once(
          into: "docker-compose.yml",
          after: /^services:\n/,
          marker: "# db-backup service (develoz:db_backup)",
          content: compose_service_content
        )
      end

      def ensure_backups_gitignored
        ensure_gitignore("/backups/")
      end

      private

      def compose_service_content
        template_path = File.join(self.class.source_root, "compose_service.tt")
        raw = File.read(template_path)
        ERB.new(raw, trim_mode: "-").result(binding)
      end
    end
  end
end
