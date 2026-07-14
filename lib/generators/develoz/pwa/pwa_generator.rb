# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class PwaGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def create_pwa_controller
        template "app/controllers/pwa_controller.rb.tt",
                 "app/controllers/pwa_controller.rb"
      end

      def create_manifest_view
        template "app/views/pwa/manifest.json.erb.tt",
                 "app/views/pwa/manifest.json.erb"
      end

      def create_service_worker_view
        template "app/views/pwa/service-worker.js.tt",
                 "app/views/pwa/service-worker.js.erb"
      end

      def create_offline_page
        template "app/views/pwa/offline.html.erb.tt",
                 "app/views/pwa/offline.html.erb"
      end

      def create_registration_js
        template "app/javascript/pwa/registration.js.tt",
                 "app/javascript/pwa/registration.js"
      end

      def insert_pwa_routes
        routes_snippet = File.read(File.join(self.class.source_root, "routes.rb.tt")).strip
        inject_once(into: "config/routes.rb",
                    content: routes_snippet,
                    before: /^end\s*$/,
                    marker: "pwa#manifest")
      end
    end
  end
end
