# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class VersioningGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def inject_app_version_constant
        inject_once(
          into: "config/initializers/constants.rb",
          content: '  APP_VERSION = ENV.fetch("APP_VERSION", "dev")',
          after: "# additional constants appended by generators\n"
        )
      end

      def create_application_helper
        helper_path = File.join(destination_root, "app/helpers/application_helper.rb")

        if File.exist?(helper_path)
          inject_once(
            into: "app/helpers/application_helper.rb",
            content: "  def app_version\n    APP_VERSION\n  end",
            before: /^end\s*$/
          )
        else
          template "app/helpers/application_helper.rb.tt", "app/helpers/application_helper.rb"
        end
      end

      def create_app_version_partial
        template "app/views/shared/_app_version.html.erb.tt",
                 "app/views/shared/_app_version.html.erb"
      end
    end
  end
end
