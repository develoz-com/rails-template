# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class FrontendCoreGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      class_option :skip_pagy, type: :boolean, default: false

      def add_frontend_gems
        add_gem "importmap-rails"
        add_gem "annotaterb", group: :development
      end

      def add_pagy_gem
        return if options[:skip_pagy]

        add_gem "pagy"
      end

      def create_importmap_config
        template "config/importmap.rb.tt", "config/importmap.rb"
      end

      def create_pagy_initializer
        return if options[:skip_pagy]

        template "config/initializers/pagy.rb.tt", "config/initializers/pagy.rb"
      end

      def create_annotaterb_config
        template ".annotaterb.yml.tt", ".annotaterb.yml"
      end
    end
  end
end
