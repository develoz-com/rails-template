# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class ConcernsGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def create_concerns
        template "app/models/concerns/searchable_concern.rb.tt", "app/models/concerns/searchable_concern.rb"
        template "app/models/concerns/optimized_finders.rb.tt", "app/models/concerns/optimized_finders.rb"
        template "app/models/concerns/transitionable.rb.tt", "app/models/concerns/transitionable.rb"
        template "app/models/concerns/configurable.rb.tt", "app/models/concerns/configurable.rb"
      end

      def create_migrations
        unless migration_exists?("add_status_transitions")
          template "db/migrate/add_status_transitions.rb.tt",
                   "db/migrate/#{next_migration_timestamp}_add_status_transitions.rb"
        end
        return if migration_exists?("create_configurations")

        template "db/migrate/create_configurations.rb.tt",
                 "db/migrate/#{next_migration_timestamp}_create_configurations.rb"
      end

      def create_concern_specs
        template "spec/models/concerns/searchable_concern_spec.rb.tt", "spec/models/concerns/searchable_concern_spec.rb"
        template "spec/models/concerns/optimized_finders_spec.rb.tt", "spec/models/concerns/optimized_finders_spec.rb"
        template "spec/models/concerns/transitionable_spec.rb.tt", "spec/models/concerns/transitionable_spec.rb"
        template "spec/models/concerns/configurable_spec.rb.tt", "spec/models/concerns/configurable_spec.rb"
      end
    end
  end
end
