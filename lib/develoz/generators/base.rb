# frozen_string_literal: true

require "rails/generators"
require_relative "feature_documentation"

module Develoz
  module Generators
    class Base < Rails::Generators::Base
      cattr_accessor :migration_counter, default: 0

      def self.next_migration_timestamp
        self.migration_counter += 1
        (Time.now.utc + migration_counter).strftime("%Y%m%d%H%M%S")
      end

      delegate :next_migration_timestamp, to: :class

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

      def add_gem(name, version = nil, group: nil, **options)
        file_path = File.join(destination_root, "Gemfile")
        return unless File.exist?(file_path)

        gemfile_content = File.read(file_path)

        if gemfile_content.match?(/^\s*gem\s+["']#{Regexp.escape(name)}["']/)
          say "Gemfile: gem '#{name}' already present, skipping", :green
          return
        end

        if group
          regex = group_regex_for(group)
          if regex
            group_match = gemfile_content.match(regex)
            if group_match
              block_start_index = group_match.begin(0)
              end_match = gemfile_content.match(/^end\b/, block_start_index)
              if end_match
                end_index = end_match.begin(0)
                options_str = options.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
                options_part = options_str.empty? ? "" : ", #{options_str}"
                gem_line = version ? "  gem \"#{name}\", \"#{version}\"#{options_part}\n" : "  gem \"#{name}\"#{options_part}\n"
                gemfile_content.insert(end_index, gem_line)
                File.write(file_path, gemfile_content)
                say "Gemfile: gem '#{name}' added to existing group", :green
                return
              end
            end
          end
        end

        gem(name, version, group: group, **options)
        gemfile = File.read(file_path)
        formatted_gemfile = gemfile.gsub(/group: \[([^\]\n]+)\]/, 'group: [ \1 ]')
        File.write(file_path, formatted_gemfile) if formatted_gemfile != gemfile
      end

      def insert_route(route_line)
        file_path = File.join(destination_root, "config/routes.rb")
        if File.exist?(file_path)
          routes_content = File.read(file_path)

          if routes_content.include?(route_line)
            say "config/routes.rb: route already present, skipping", :green
            return
          end

          inject_into_file("config/routes.rb", "  #{route_line}\n", before: /^end\s*$/)
        else
          false
        end
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

      def migration_exists?(name)
        Dir.glob(File.join(destination_root, "db/migrate/*_#{name}.rb")).any?
      end

      def apply_template(name, destination)
        template_file = File.join(self.class.source_root, name)
        return unless File.exist?(template_file)

        copy_file(name, destination)
      end

      private

      def group_regex_for(group)
        case group
        when Array
          sorted = group.map(&:to_sym).sort
          if sorted == %i[development test]
            /group\s+(?::development\s*,\s*:test|:test\s*,\s*:development|%i\[\s*(?:development\s+test|test\s+development)\s*\]|%w\[\s*(?:development\s+test|test\s+development)\s*\]|\[\s*(?::development\s*,\s*:test|:test\s*,\s*:development)\s*\])\s+do/
          else
            /group\s+.*do/
          end
        when :development, "development"
          /group\s+(?::development|%i\[\s*development\s*\]|%w\[\s*development\s*\])\s+do/
        when :test, "test"
          /group\s+(?::test|%i\[\s*test\s*\]|%w\[\s*test\s*\])\s+do/
        end
      end

      remove_task(*public_instance_methods(false))
    end

    Base.prepend FeatureDocumentationLifecycle
  end
end
