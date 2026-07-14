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

      def create_rails_helper
        template "spec/rails_helper.rb.tt", "spec/rails_helper.rb"
      end

      def create_rspec_parallel_config
        template "rspec_parallel.tt", ".rspec_parallel"
      end
    end
  end
end
