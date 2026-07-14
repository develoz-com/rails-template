# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/docs_render/docs_render_generator"

RSpec.describe Develoz::Generators::DocsRenderGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.add_docs_gems
    gen.create_docs_controller
    gen.create_document_model
    gen.create_docs_views
    gen.create_docs_javascript
    gen.create_docs_stylesheet
    gen.create_redcarpet_rouge_initializer
    gen.insert_docs_route
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds redcarpet gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("redcarpet")
    end
  end

  it "adds rouge gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("rouge")
    end
  end

  it "generates docs_controller.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/controllers/docs_controller.rb"))
    end
  end

  it "docs_controller inherits from ApplicationController" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/docs_controller.rb"))
      expect(content).to include("class DocsController < ApplicationController")
    end
  end

  it "docs_controller has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/docs_controller.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates document.rb model" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/document.rb"))
    end
  end

  it "document model includes Redcarpet renderer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/document.rb"))
      expect(content).to include("Redcarpet::Render::HTML")
    end
  end

  it "document model includes Rouge syntax highlighting" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/document.rb"))
      expect(content).to include("Rouge::Lexer")
    end
  end

  it "document model has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/document.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates show.html.erb view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/docs/show.html.erb"))
    end
  end

  it "show view renders document" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/docs/show.html.erb"))
      expect(content).to include("@document.render")
    end
  end

  it "show view includes docs javascript" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/docs/show.html.erb"))
      expect(content).to include("javascript_include_tag")
    end
  end

  it "generates docs.js" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/javascript/docs.js"))
    end
  end

  it "docs.js imports mermaid" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/javascript/docs.js"))
      expect(content).to include("mermaid")
    end
  end

  it "generates documentation.scss" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/assets/stylesheets/documentation.scss"))
    end
  end

  it "documentation.scss has documentation section" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/assets/stylesheets/documentation.scss"))
      expect(content).to include("section.documentation")
    end
  end

  it "generates redcarpet_rouge initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/redcarpet_rouge.rb"))
    end
  end

  it "initializer mentions Redcarpet and Rouge" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/redcarpet_rouge.rb"))
      expect(content).to include("Redcarpet")
      expect(content).to include("Rouge")
    end
  end

  it "initializer has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/redcarpet_rouge.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "inserts docs route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include('get "docs(/*id)" => "docs#show"')
    end
  end

  it "is idempotent for gems" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("redcarpet").size).to eq(1)
      expect(gemfile.scan("rouge").size).to eq(1)
    end
  end

  it "is idempotent for route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes.scan("docs#show").size).to eq(1)
    end
  end

  it "is idempotent for docs_controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/controllers/docs_controller.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/controllers/docs_controller.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for document model" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/models/document.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/models/document.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for show view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/docs/show.html.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/docs/show.html.erb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for docs.js" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/javascript/docs.js"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/javascript/docs.js"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for stylesheet" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/assets/stylesheets/documentation.scss"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/assets/stylesheets/documentation.scss"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/initializers/redcarpet_rouge.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/initializers/redcarpet_rouge.rb"))
      expect(first).to eq(second)
    end
  end
end
