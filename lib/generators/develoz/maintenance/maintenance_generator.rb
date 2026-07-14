# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class MaintenanceGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_maintenance_tasks_gem
        add_gem "maintenance_tasks"
      end

      def insert_maintenance_tasks_route
        insert_route('mount MaintenanceTasks::Engine, at: "/maintenance_tasks"')
      end

      def create_example_task
        template "app/tasks/maintenance/example_task.rb.tt", "app/tasks/maintenance/example_task.rb"
      end

      def create_rake_task
        template "lib/tasks/maintenance_counters.rake.tt", "lib/tasks/maintenance_counters.rake"
      end
    end
  end
end
