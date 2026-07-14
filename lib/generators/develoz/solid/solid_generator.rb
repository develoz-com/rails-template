# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class SolidGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_solid_gems
        add_gem "solid_queue"
        add_gem "solid_cache"
        add_gem "solid_cable"
        add_gem "mission_control-jobs"
      end

      def create_queue_config
        template "config/queue.yml.tt", "config/queue.yml"
      end

      def create_cache_config
        template "config/cache.yml.tt", "config/cache.yml"
      end

      def create_cable_config
        template "config/cable.yml.tt", "config/cable.yml"
      end

      def create_recurring_config
        template "config/recurring.yml.tt", "config/recurring.yml"
      end

      def create_application_job
        template "app/jobs/application_job.rb.tt", "app/jobs/application_job.rb"
      end

      def create_mission_control_initializer
        template "config/initializers/mission_control.rb.tt", "config/initializers/mission_control.rb"
      end

      def create_solid_initializer
        template "config/initializers/solid.rb.tt", "config/initializers/solid.rb"
      end

      def insert_mission_control_route
        insert_route('mount MissionControl::Jobs::Engine, at: "/jobs"')
      end
    end
  end
end
