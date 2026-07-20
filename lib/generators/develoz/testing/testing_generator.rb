# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class TestingGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_test_gems
        add_gem "rspec-rails", group: %i[development test]
        add_gem "capybara", group: %i[test]
        add_gem "selenium-webdriver", group: %i[test]
        add_gem "simplecov", require: false, group: %i[test]
        add_gem "simplecov-lcov", require: false, group: %i[test]
        add_gem "parallel_tests", group: %i[test]
        add_gem "factory_bot_rails", group: %i[test]
      end

      def create_rspec_config
        template "rspec.tt", ".rspec"
      end

      def create_spec_helper
        template "spec/spec_helper.rb.tt", "spec/spec_helper.rb"
      end

      SYSTEM_DRIVER_HOOK = "  config.before(type: :system) " \
                           '{ driven_by ENV["SCREENSHOTS"] == "true" ? :headless_chrome : :rack_test }'
      SYSTEM_JS_DRIVER_HOOK = "  config.before(type: :system, js: true) { driven_by :headless_chrome }"

      def create_rails_helper
        helper_path = File.join(destination_root, "spec/rails_helper.rb")
        if File.exist?(helper_path)
          [
            "  config.infer_spec_type_from_file_location!",
            SYSTEM_DRIVER_HOOK,
            SYSTEM_JS_DRIVER_HOOK
          ].each do |content|
            inject_once(into: "spec/rails_helper.rb", content: content, after: "RSpec.configure do |config|\n")
          end
        else
          template "spec/rails_helper.rb.tt", "spec/rails_helper.rb"
        end
      end

      def create_rspec_parallel_config
        template "rspec_parallel.tt", ".rspec_parallel"
      end

      def create_spec_parallel_task
        template "lib/tasks/spec_parallel.rake.tt", "lib/tasks/spec_parallel.rake"
      end
    end
  end
end
