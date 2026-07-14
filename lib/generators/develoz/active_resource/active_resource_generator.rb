# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class ActiveResourceGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_activeresource_gem
        add_gem "activeresource"
      end

      def create_application_resource
        template "application_resource.rb.tt", "app/models/application_resource.rb"
      end

      def create_example_resource
        template "example_resource.rb.tt", "app/models/example_resource.rb"
      end
    end
  end
end
