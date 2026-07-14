# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class StrictLoadingGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def create_strict_loading_initializer
        template "config/initializers/strict_loading.rb.tt", "config/initializers/strict_loading.rb"
      end
    end
  end
end
