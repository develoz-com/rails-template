# frozen_string_literal: true

require "thor"
require "tty-prompt"
require_relative "version"

module Develoz
  class CLI < Thor
    OPT_IN_FLAGS = %i[api auth pwa push active_resource admin ui kamal docker db_backup].freeze
    FLAG_LABELS = {
      api: "API layer", auth: "authentication", pwa: "PWA support",
      push: "push notifications", active_resource: "ActiveResource",
      admin: "admin dashboard", ui: "develoz-ui", kamal: "Kamal deployment",
      docker: "Docker setup", db_backup: "database backups"
    }.freeze
    RAILS_NEW_SKIPS = %w[--skip-test --skip-ci --skip-bundle].freeze

    desc "version", "Show version"
    def version
      puts "develoz #{Develoz::VERSION}"
    end

    desc "new APP_NAME", "Generate a new Develoz Rails app"
    option :api, type: :boolean
    option :auth, type: :boolean
    option :pwa, type: :boolean
    option :push, type: :boolean
    option :active_resource, type: :boolean
    option :admin, type: :boolean
    option :ui, type: :boolean
    option :kamal, type: :boolean
    option :docker, type: :boolean
    option :db_backup, type: :boolean
    option :skip_pagy, type: :boolean
    option :ruby, type: :string
    option :rails, type: :string
    option :yes, type: :boolean
    def new(app_name)
      resolved = resolve_flags
      resolver = Develoz::VersionResolver.new
      versions = resolver.resolve(ruby: options[:ruby], rails: options[:rails])
      run_rails_new(app_name, versions[:rails])
      write_version_files(app_name, versions, resolver)
      invoke_install(app_name, resolved)
      puts "Created #{app_name} with Develoz Rails template."
    end

    private

    def resolve_flags
      OPT_IN_FLAGS.index_with { |flag| resolve_flag(flag) }
    end

    def resolve_flag(flag)
      return options[flag] unless options[flag].nil?
      return false if options[:yes]

      prompt.yes?("Include #{FLAG_LABELS[flag]}?")
    end

    def prompt
      @prompt ||= TTY::Prompt.new
    end

    def run_rails_new(app_name, rails_version)
      return if system("rails", "new", app_name, "--rails-version=#{rails_version}", *RAILS_NEW_SKIPS)

      raise "Failed to generate Rails app: #{app_name}"
    end

    def write_version_files(app_name, versions, resolver)
      dir = File.expand_path(app_name)
      resolver.write_tool_versions(dir, ruby: versions[:ruby])
      resolver.write_ruby_version(dir, ruby: versions[:ruby])
    end

    def invoke_install(app_name, resolved)
      opts = resolved.merge(skip_pagy: options[:skip_pagy])
      Dir.chdir(app_name) do
        Develoz::Generators::InstallGenerator.new([], opts, destination_root: Dir.pwd).install
      end
    end
  end
end
