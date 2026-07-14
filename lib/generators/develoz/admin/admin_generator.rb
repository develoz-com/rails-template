# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class AdminGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      class_option :ui, type: :boolean, default: false

      def create_admin_base_controller
        template "admin_base_controller.rb.tt", "app/controllers/admin/base_controller.rb"
      end

      def create_admin_layout
        template "admin_layout.html.erb.tt", "app/views/layouts/admin.html.erb"
      end

      def create_dashboard_controller
        template "dashboard_controller.rb.tt", "app/controllers/admin/dashboard_controller.rb"
      end

      def create_dashboard_view
        template "dashboard_index.html.erb.tt",
                 "app/views/admin/dashboard/index.html.erb"
      end

      def insert_admin_routes
        inject_once(
          into: "config/routes.rb",
          content: "  namespace :admin do\n    root \"dashboard#index\"\n  end",
          before: /^end\s*$/
        )
      end

      def ui_enabled?
        options[:ui]
      end
    end
  end
end
