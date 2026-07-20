# frozen_string_literal: true

require "spec_helper"
require "digest/sha2"
require "fileutils"
require "tmpdir"
require "generators/develoz/install/install_generator"

RSpec.describe "core generator adoption", :e2e do # rubocop:disable RSpec/DescribeClass
  let(:destination_root) { Dir.mktmpdir("develoz-existing-app") }

  before do
    FileUtils.cp_r("#{fixture_root}/.", destination_root)
    File.binwrite(File.join(destination_root, "README.md"), original_readme)
    run_generators
  end

  after { FileUtils.remove_entry(destination_root) }

  def fixture_root
    File.expand_path("../fixtures/existing_app", __dir__)
  end

  def original_readme
    "# Existing Rails Application\r\n\r\nKeep this adoption guidance byte-for-byte."
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
    Develoz::Generators::InstallGenerator.new([], {}, destination_root: destination_root).invoke_all
  end

  def expected_entries
    Develoz::Manifest.for(Develoz::Options.new)
  end

  def expected_documentation_paths
    expected_entries.map { |entry| "docs/#{entry.documentation_slug}.md" }
  end

  def managed_documentation_paths(path)
    content = generated_content(path)
    block = content.match(
      /#{Regexp.escape(Develoz::Generators::FeatureDocumentation::BEGIN_MARKER)}.*?#{Regexp.escape(Develoz::Generators::FeatureDocumentation::END_MARKER)}/mo
    ).to_s
    block.scan(%r{\(docs/([^)]+\.md)\)}).flatten.map { |target| "docs/#{target}" }
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

  it "creates exactly the 13 core feature guides and links in manifest order" do
    aggregate_failures do
      expect(expected_entries.size).to eq(13)
      expect(managed_documentation_paths("README.md")).to eq(expected_documentation_paths)
      expect(managed_documentation_paths("AGENTS.md")).to eq(expected_documentation_paths)
      expect(expected_documentation_paths).to all(satisfy { |path| File.file?(File.join(destination_root, path)) })
    end
  end

  it "retains the existing README and generates the full AGENTS template outside managed blocks" do
    aggregate_failures do
      expect(generated_content("README.md")).to start_with(original_readme)
      expect(generated_content("AGENTS.md")).to include("Development Environment", "Quality Expectations")
      expect(generated_content("AGENTS.md").index("Quality Expectations"))
        .to be < generated_content("AGENTS.md").index("## Feature Documentation")
    end
  end

  it "is idempotent across every generated file" do
    first_run = file_digests

    run_generators

    expect(file_digests).to eq(first_run)
  end
end
