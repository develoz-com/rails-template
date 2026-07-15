# frozen_string_literal: true

require "rails/generators"

module Develoz
  module Generators
    class Base < Rails::Generators::Base
      def self.source_root
        File.expand_path("../../../templates", __dir__)
      end

      def app_name
        File.basename(destination_root)
      end

      def app_class
        app_name.camelize
      end

      def inject_once(into:, content:, after: nil, before: nil, marker: nil)
        file_path = File.join(destination_root, into)
        return unless File.exist?(file_path)

        file_content = File.read(file_path)

        if marker && file_content.include?(marker)
          say "#{into}: marker '#{marker}' already present, skipping", :green
          return
        end

        if file_content.include?(content)
          say "#{into}: content already present, skipping", :green
          return
        end

        if after
          inject_into_file(into, "#{content}\n", after: after)
        elsif before
          inject_into_file(into, "#{content}\n", before: before)
        else
          inject_into_file(into, "#{content}\n")
        end
      end

      def add_gem(name, version = nil, group: nil, **)
        file_path = File.join(destination_root, "Gemfile")
        return unless File.exist?(file_path)

        gemfile_content = File.read(file_path)

        if gemfile_content.match?(/^\s*gem\s+["']#{Regexp.escape(name)}["']/)
          say "Gemfile: gem '#{name}' already present, skipping", :green
          return
        end

        gem(name, version, group: group, **)
      end

      def insert_route(route_line)
        file_path = File.join(destination_root, "config/routes.rb")
        return unless File.exist?(file_path)

        routes_content = File.read(file_path)

        if routes_content.include?(route_line)
          say "config/routes.rb: route already present, skipping", :green
          return
        end

        inject_into_file("config/routes.rb", "  #{route_line}\n", before: /^end\s*$/)
      end

      def append_env(key, value, example: true)
        env_file = File.join(destination_root, ".env")
        env_example_file = File.join(destination_root, ".env.example")

        if File.exist?(env_file)
          env_content = File.read(env_file)
          if env_content.include?("#{key}=")
            say ".env: key '#{key}' already present, skipping", :green
          else
            append_to_file(".env", "#{key}=#{value}\n")
          end
        end

        return unless example && File.exist?(env_example_file)

        example_content = File.read(env_example_file)
        if example_content.include?("#{key}=")
          say ".env.example: key '#{key}' already present, skipping", :green
        else
          append_to_file(".env.example", "#{key}=\n")
        end
      end

      def ensure_gitignore(pattern)
        file_path = File.join(destination_root, ".gitignore")
        return unless File.exist?(file_path)

        gitignore_content = File.read(file_path)

        if gitignore_content.include?(pattern)
          say ".gitignore: pattern '#{pattern}' already present, skipping", :green
          return
        end

        append_to_file(".gitignore", "#{pattern}\n")
      end

      def apply_template(name, destination)
        template_file = File.join(self.class.source_root, name)
        return unless File.exist?(template_file)

        copy_file(name, destination)
      end
    end
  end
end
