# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class InstallGenerator < Develoz::Generators::Base
      class_option :api, type: :boolean, default: false
      class_option :auth, type: :boolean, default: false
      class_option :pwa, type: :boolean, default: false
      class_option :push, type: :boolean, default: false
      class_option :active_resource, type: :boolean, default: false
      class_option :admin, type: :boolean, default: false
      class_option :ui, type: :boolean, default: false
      class_option :kamal, type: :boolean, default: false
      class_option :docker, type: :boolean, default: false
      class_option :db_backup, type: :boolean, default: false
      class_option :skip_pagy, type: :boolean, default: false

      def install
        develoz_options = build_options
        entries = Develoz::Manifest.for(develoz_options)
        invoked_entries = entries.select do |entry|
          invoke_generator(entry.name, develoz_options.to_h)
        end
        FeatureDocumentation.reconcile(destination_root:, entries: invoked_entries, mode: :authoritative)
      end

      private

      OPTION_FLAGS = %i[api auth pwa push active_resource admin ui kamal docker db_backup skip_pagy].freeze
      private_constant :OPTION_FLAGS

      def build_options
        flags = OPTION_FLAGS.index_with { |flag| options[flag] }
        Develoz::Options.new(**flags, app_name: app_name)
      end

      def invoke_generator(name, generator_options)
        require "generators/develoz/#{name}/#{name}_generator"
        klass = Develoz::Generators.const_get("#{name.camelize}Generator")
        gen = klass.new([], generator_options, destination_root: destination_root)
        gen.defer_feature_documentation!
        gen.invoke_all
        true
      rescue LoadError
        say "generator develoz:#{name} not yet available", :yellow
        false
      rescue NameError => e
        raise unless e.name.to_s == "#{name.camelize}Generator"

        say "generator develoz:#{name} not yet available", :yellow
        false
      end
    end
  end
end
