# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/api/api_generator"

RSpec.describe Develoz::Generators::ApiGenerator do
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
    gen.add_api_gems
    gen.create_base_controller
    gen.create_blueprinter_initializer
    gen.create_example_blueprint
    gen.create_rswag_api_initializer
    gen.create_rswag_ui_initializer
    gen.insert_rswag_routes
    gen.create_example_request_spec
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds blueprinter gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("blueprinter")
    end
  end

  it "adds rswag-api gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("rswag-api")
    end
  end

  it "adds rswag-ui gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("rswag-ui")
    end
  end

  it "adds rswag-specs gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("rswag-specs")
    end
  end

  it "generates base controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/controllers/api/v1/base_controller.rb"))
    end
  end

  it "base controller has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/api/v1/base_controller.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "base controller inherits from ApplicationController" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/api/v1/base_controller.rb"))
      expect(content).to include("class BaseController < ApplicationController")
    end
  end

  it "base controller includes Pagy::Backend" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/api/v1/base_controller.rb"))
      expect(content).to include("include Pagy::Backend")
    end
  end

  it "base controller has authenticate stub" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/api/v1/base_controller.rb"))
      expect(content).to include("def authenticate; end")
    end
  end

  it "base controller has render_json_error" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/api/v1/base_controller.rb"))
      expect(content).to include("def render_json_error")
    end
  end

  it "generates blueprinter initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/blueprinter.rb"))
    end
  end

  it "blueprinter initializer has LowerCamelTransformer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/blueprinter.rb"))
      expect(content).to include("class LowerCamelTransformer")
    end
  end

  it "blueprinter initializer sets default_transformers" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/blueprinter.rb"))
      expect(content).to include("config.default_transformers = [LowerCamelTransformer]")
    end
  end

  it "blueprinter initializer has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/blueprinter.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates example blueprint" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/blueprints/example_blueprint.rb"))
    end
  end

  it "example blueprint inherits from Blueprinter::Base" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/blueprints/example_blueprint.rb"))
      expect(content).to include("class ExampleBlueprint < Blueprinter::Base")
    end
  end

  it "generates rswag_api initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/rswag_api.rb"))
    end
  end

  it "rswag_api initializer has openapi_root" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/rswag_api.rb"))
      expect(content).to include("c.openapi_root")
    end
  end

  it "generates rswag_ui initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/rswag_ui.rb"))
    end
  end

  it "rswag_ui initializer has openapi_endpoint" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/rswag_ui.rb"))
      expect(content).to include("c.openapi_endpoint")
    end
  end

  it "rswag_ui initializer references v1 swagger" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/rswag_ui.rb"))
      expect(content).to include("/api-docs/v1/swagger.yaml")
    end
  end

  it "inserts rswag ui route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include("mount Rswag::Ui::Engine => '/api-docs'")
    end
  end

  it "inserts rswag api route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include("mount Rswag::Api::Engine => '/api-docs'")
    end
  end

  it "generates example request spec" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/requests/api/v1/examples_spec.rb"))
    end
  end

  it "example spec has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/api/v1/examples_spec.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "example spec uses rswag path DSL" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/api/v1/examples_spec.rb"))
      expect(content).to include("path '/api/v1/examples'")
    end
  end

  it "example spec uses rswag response DSL" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/api/v1/examples_spec.rb"))
      expect(content).to include("response '200'")
    end
  end

  it "is idempotent for gems" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan(/^\s*gem\s+["']blueprinter["']/m).length).to eq(1)
    end
  end

  it "is idempotent for base controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/controllers/api/v1/base_controller.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/controllers/api/v1/base_controller.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for blueprinter initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/initializers/blueprinter.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/initializers/blueprinter.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for example blueprint" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/blueprints/example_blueprint.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/blueprints/example_blueprint.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for rswag_api initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/initializers/rswag_api.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/initializers/rswag_api.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for rswag_ui initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/initializers/rswag_ui.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/initializers/rswag_ui.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for routes" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes.scan("mount Rswag::Ui::Engine").length).to eq(1)
    end
  end

  it "is idempotent for example spec" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/requests/api/v1/examples_spec.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/requests/api/v1/examples_spec.rb"))
      expect(first).to eq(second)
    end
  end
end
