# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class DocsRenderGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_docs_gems
        add_gem "redcarpet"
        add_gem "rouge"
      end

      def create_docs_controller
        template "app/controllers/docs_controller.rb.tt", "app/controllers/docs_controller.rb"
      end

      def create_document_model
        template "app/models/document.rb.tt", "app/models/document.rb"
      end

      def create_docs_views
        template "app/views/docs/show.html.erb.tt", "app/views/docs/show.html.erb"
      end

      def create_docs_javascript
        template "app/javascript/docs.js.tt", "app/javascript/docs.js"
      end

      def create_docs_stylesheet
        template "app/assets/stylesheets/documentation.scss.tt", "app/assets/stylesheets/documentation.scss"
      end

      def create_redcarpet_rouge_initializer
        template "config/initializers/redcarpet_rouge.rb.tt", "config/initializers/redcarpet_rouge.rb"
      end

      def insert_docs_route
        insert_route 'get "docs(/*id)" => "docs#show"'
      end
    end
  end
end
