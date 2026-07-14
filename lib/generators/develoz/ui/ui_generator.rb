# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class UiGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_develoz_ui_gems
        inject_once(
          into: "Gemfile",
          content: <<~RUBY
            group :development, :test do
              gem "develoz_ui", path: "vendor/develoz-ui"
            end

            group :production do
              gem "develoz_ui", github: "develoz-com/develoz-ui"
            end
          RUBY
        )
      end

      def create_gitmodules
        gitmodules_path = File.join(destination_root, ".gitmodules")
        File.write(gitmodules_path, "") unless File.exist?(gitmodules_path)

        inject_once(
          into: ".gitmodules",
          content: "[submodule \"vendor/develoz-ui\"]\n" \
                   "\tpath = vendor/develoz-ui\n" \
                   "\turl = git@github.com:develoz-com/develoz-ui.git"
        )
      end

      def create_setup_script
        template "bin/setup_develoz_ui.tt", "bin/setup_develoz_ui"
        dest = File.join(destination_root, "bin/setup_develoz_ui")
        File.chmod(0o755, dest)
      end

      def inject_importmap_pins
        inject_once(
          into: "config/importmap.rb",
          content: <<~RUBY
            # develoz-ui Stimulus controllers
            pin "develoz-ui", to: "develoz-ui/index.js"
            pin_all_from "vendor/develoz-ui/app/javascript/controllers", under: "develoz-ui/controllers"
          RUBY
        )
      end
    end
  end
end
