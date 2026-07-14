# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class DocSpecsGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def create_generate_docs_script
        template "bin/generate-docs.tt", "bin/generate-docs"
        dest = File.join(destination_root, "bin/generate-docs")
        File.chmod(0o755, dest)
      end

      def create_doc_screenshot_helper
        template "spec/support/doc_screenshot_helper.rb.tt",
                 "spec/support/doc_screenshot_helper.rb"
      end

      def create_docs_check_rake_task
        template "lib/tasks/docs_check.rake.tt", "lib/tasks/docs_check.rake"
      end

      def create_example_system_spec
        template "spec/system/example_doc_spec.rb.tt",
                 "spec/system/example_doc_spec.rb"
      end
    end
  end
end
