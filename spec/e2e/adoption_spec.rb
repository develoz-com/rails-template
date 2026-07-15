# frozen_string_literal: true

require "spec_helper"
require "digest/sha2"
require "fileutils"
require "tmpdir"
require "generators/develoz/tooling/tooling_generator"
require "generators/develoz/testing/testing_generator"
require "generators/develoz/solid/solid_generator"
require "generators/develoz/ci/ci_generator"
require "generators/develoz/database/database_generator"
require "generators/develoz/concerns/concerns_generator"
require "generators/develoz/strict_loading/strict_loading_generator"
require "generators/develoz/maintenance/maintenance_generator"
require "generators/develoz/frontend_core/frontend_core_generator"
require "generators/develoz/docs_render/docs_render_generator"
require "generators/develoz/agents_docs/agents_docs_generator"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "core generator adoption", :e2e do
  let(:destination_root) { Dir.mktmpdir("develoz-existing-app") }

  before do
    FileUtils.cp_r("#{fixture_root}/.", destination_root)
    run_generators
  end

  after { FileUtils.remove_entry(destination_root) }

  def fixture_root
    File.expand_path("../fixtures/existing_app", __dir__)
  end

  def generator_classes
    [
      Develoz::Generators::ToolingGenerator,
      Develoz::Generators::TestingGenerator,
      Develoz::Generators::SolidGenerator,
      Develoz::Generators::CiGenerator,
      Develoz::Generators::DatabaseGenerator,
      Develoz::Generators::ConcernsGenerator,
      Develoz::Generators::StrictLoadingGenerator,
      Develoz::Generators::MaintenanceGenerator,
      Develoz::Generators::FrontendCoreGenerator,
      Develoz::Generators::DocsRenderGenerator,
      Develoz::Generators::AgentsDocsGenerator
    ]
  end

  def generated_files
    %w[
      .vscode/settings.json
      spec/spec_helper.rb
      config/queue.yml
      bin/ci
      config/database.yml
      app/models/concerns/searchable_concern.rb
      config/initializers/strict_loading.rb
      app/tasks/maintenance/example_task.rb
      config/importmap.rb
      app/controllers/docs_controller.rb
      AGENTS.md
    ]
  end

  def run_generators
    generator_classes.each do |generator_class|
      generator = generator_class.new([], {}, destination_root: destination_root)
      generator_class.public_instance_methods(false).each { |method| generator.public_send(method) }
    end
  end

  def generated_content(path)
    File.read(File.join(destination_root, path))
  end

  def fixture_content(path)
    File.read(File.join(fixture_root, path))
  end

  def file_digests
    paths = Dir.glob("**/*", File::FNM_DOTMATCH, base: destination_root)
               .select { |path| File.file?(File.join(destination_root, path)) }
    paths.index_with { |path| Digest::SHA256.file(File.join(destination_root, path)).hexdigest }
  end

  it "preserves pre-existing application code byte-for-byte" do
    paths = %w[config/application.rb app/models/post.rb app/controllers/posts_controller.rb]
    generated = paths.index_with { |path| generated_content(path) }
    fixture = paths.index_with { |path| fixture_content(path) }

    expect(generated).to eq(fixture)
  end

  it "preserves existing dependency and configuration entries" do
    aggregate_failures do
      expect(generated_content("Gemfile")).to start_with(fixture_content("Gemfile"))
      expect(generated_content("config/routes.rb")).to include("resources :posts", 'root "posts#index"')
      expect(generated_content(".gitignore")).to start_with(fixture_content(".gitignore"))
      expect(generated_content(".tool-versions")).to start_with(fixture_content(".tool-versions"))
    end
  end

  it "adds core dependencies, routes, and files" do
    aggregate_failures do
      expect(generated_content("Gemfile")).to include('gem "dotenv-rails"', 'gem "solid_queue"', 'gem "faraday"')
      expect(generated_content("config/routes.rb")).to include(
        "MissionControl::Jobs", "MaintenanceTasks::Engine", 'get "docs'
      )
      expect(generated_files.select { |path| File.file?(File.join(destination_root, path)) }).to eq(generated_files)
      expect(generated_content(".gitignore")).to include(".env")
      expect(generated_content(".tool-versions")).to include("postgres 18")
    end
  end

  it "is idempotent across every generated file" do
    first_run = file_digests

    run_generators

    expect(file_digests).to eq(first_run)
  end
end
# rubocop:enable RSpec/DescribeClass
