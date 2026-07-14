# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class ApiGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_api_gems
        add_gem "blueprinter"
        add_gem "rswag-api"
        add_gem "rswag-ui"
        add_gem "rswag-specs", group: %i[test]
      end

      def create_base_controller
        template "app/controllers/api/v1/base_controller.rb.tt",
                 "app/controllers/api/v1/base_controller.rb"
      end

      def create_blueprinter_initializer
        template "config/initializers/blueprinter.rb.tt",
                 "config/initializers/blueprinter.rb"
      end

      def create_example_blueprint
        template "app/blueprints/example_blueprint.rb.tt",
                 "app/blueprints/example_blueprint.rb"
      end

      def create_rswag_api_initializer
        template "config/initializers/rswag_api.rb.tt",
                 "config/initializers/rswag_api.rb"
      end

      def create_rswag_ui_initializer
        template "config/initializers/rswag_ui.rb.tt",
                 "config/initializers/rswag_ui.rb"
      end

      def insert_rswag_routes
        insert_route "mount Rswag::Ui::Engine => '/api-docs'"
        insert_route "mount Rswag::Api::Engine => '/api-docs'"
      end

      def create_example_request_spec
        template "spec/requests/api/v1/examples_spec.rb.tt",
                 "spec/requests/api/v1/examples_spec.rb"
      end
    end
  end
end
