# frozen_string_literal: true

module Develoz
  class Options
    # Opt-in feature flags (default false)
    OPT_IN_FLAGS = %i[api auth pwa push active_resource admin ui kamal docker db_backup].freeze

    # Opt-out flags (default false → feature is included unless skipped)
    OPT_OUT_FLAGS = %i[skip_pagy].freeze

    # All valid flag keys
    VALID_KEYS = (OPT_IN_FLAGS + OPT_OUT_FLAGS + %i[app_name ruby_version rails_version]).freeze

    attr_reader :app_name, :ruby_version, :rails_version

    def initialize(options = {})
      unknown_keys = options.keys - VALID_KEYS
      raise ArgumentError, "Unknown option(s): #{unknown_keys.join(', ')}" if unknown_keys.any?

      @app_name = options[:app_name]
      @ruby_version = options[:ruby_version]
      @rails_version = options[:rails_version]

      # Initialize opt-in flags (default false)
      OPT_IN_FLAGS.each do |flag|
        instance_variable_set("@#{flag}", options[flag] || false)
      end

      # Initialize opt-out flags (default false)
      OPT_OUT_FLAGS.each do |flag|
        instance_variable_set("@#{flag}", options[flag] || false)
      end
    end

    # Predicate readers for opt-in flags
    OPT_IN_FLAGS.each do |flag|
      define_method("#{flag}?") { instance_variable_get("@#{flag}") }
    end

    # Predicate readers for opt-out flags
    OPT_OUT_FLAGS.each do |flag|
      define_method("#{flag}?") { instance_variable_get("@#{flag}") }
    end

    def to_h
      {
        app_name: @app_name,
        ruby_version: @ruby_version,
        rails_version: @rails_version,
        **OPT_IN_FLAGS.index_with { |flag| instance_variable_get("@#{flag}") },
        **OPT_OUT_FLAGS.index_with { |flag| instance_variable_get("@#{flag}") }
      }
    end
  end
end
