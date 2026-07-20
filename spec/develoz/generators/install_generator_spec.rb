# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/admin/admin_generator"
require "generators/develoz/db_backup/db_backup_generator"
require "generators/develoz/frontend_core/frontend_core_generator"
require "generators/develoz/install/install_generator"
require "generators/develoz/kamal/kamal_generator"

RSpec.describe Develoz::Generators::InstallGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      File.write(File.join(dir, ".gitignore"), "/log\n")
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
      yield dir
    end
  end

  def run_install(tmp, opts = {})
    gen = described_class.new([], opts, destination_root: tmp)
    gen.invoke_all
    gen
  end

  def manifest_entry(name)
    Develoz::Manifest.all.find { |entry| entry.name == name }
  end

  def stub_generator_load_error(gen, path)
    allow(gen).to receive(:require).and_wrap_original do |method, req_path|
      raise LoadError if req_path == path

      method.call(req_path)
    end
  end

  def expect_generator_options(generator_class, destination_root, expected_options)
    expect(generator_class).to have_received(:new)
      .with([], hash_including(expected_options), destination_root: destination_root)
  end

  it "binds destination_root" do
    with_tmp_dir { |tmp| expect(described_class.new([], {}, destination_root: tmp).destination_root).to eq(tmp) }
  end

  it "creates files from multiple core generators" do
    with_tmp_dir do |tmp|
      run_install(tmp)
      expect(File).to exist(File.join(tmp, ".vscode/settings.json"))
      expect(File).to exist(File.join(tmp, "config/queue.yml"))
      expect(File).to exist(File.join(tmp, "spec/spec_helper.rb"))
    end
  end

  it "creates database and constants config" do
    with_tmp_dir do |tmp|
      run_install(tmp)
      expect(File).to exist(File.join(tmp, "config/database.yml"))
      expect(File).to exist(File.join(tmp, "config/initializers/constants.rb"))
    end
  end

  it "runs child generators through invoke_all with deferred reconciliation" do
    with_tmp_dir do |tmp|
      child = instance_double(Develoz::Generators::ToolingGenerator)
      allow(Develoz::Generators::ToolingGenerator).to receive(:new).and_return(child)
      allow(child).to receive(:defer_feature_documentation!)
      allow(child).to receive(:invoke_all)

      result = described_class.new([], {}, destination_root: tmp).send(:invoke_generator, "tooling", {})

      expect(child).to have_received(:defer_feature_documentation!).ordered
      expect(child).to have_received(:invoke_all).ordered
      expect(result).to be(true)
    end
  end

  it "authoritatively reconciles selected documentation after successful generators" do
    with_tmp_dir do |tmp|
      File.write(File.join(tmp, "README.md"), "# App\n")
      run_install(tmp, api: true)
      content = File.read(File.join(tmp, "README.md"))

      expect(content).to include("docs/tooling.md", "docs/api.md")
      expect(content.scan("BEGIN DEVELOZ FEATURE DOCUMENTATION").size).to eq(1)
    end
  end

  it "excludes skipped generators from reconciled documentation" do
    with_tmp_dir do |tmp|
      File.write(File.join(tmp, "README.md"), "# App\n")
      gen = described_class.new([], { api: true }, destination_root: tmp)
      stub_generator_load_error(gen, "generators/develoz/api/api_generator")
      expect { gen.invoke_all }.to output(/not yet available/).to_stdout
      content = File.read(File.join(tmp, "README.md"))

      aggregate_failures do
        expect(content).to include("docs/#{manifest_entry('tooling').documentation_slug}.md")
        expect(content).not_to include("docs/#{manifest_entry('api').documentation_slug}.md")
        expect(content.scan("BEGIN DEVELOZ FEATURE DOCUMENTATION").size).to eq(1)
      end
    end
  end

  it "does not reconcile documentation when a selected generator fails" do
    with_tmp_dir do |tmp|
      generator = described_class.new([], {}, destination_root: tmp)
      allow(generator).to receive(:invoke_generator).and_raise("failed generator")

      expect { generator.invoke_all }.to raise_error("failed generator")
      expect(File).not_to exist(File.join(tmp, "README.md"))
    end
  end

  it "is idempotent for gems" do
    with_tmp_dir do |tmp|
      run_install(tmp)
      run_install(tmp)
      expect(File.read(File.join(tmp, "Gemfile")).scan("dotenv-rails").size).to eq(1)
    end
  end

  it "forwards resolved options to option-aware generators" do
    with_tmp_dir do |tmp|
      generators = [Develoz::Generators::FrontendCoreGenerator, Develoz::Generators::AdminGenerator,
                    Develoz::Generators::KamalGenerator, Develoz::Generators::DbBackupGenerator]
      generators.each { |generator| allow(generator).to receive(:new).and_call_original }
      run_install(tmp, skip_pagy: true, admin: true, ui: true, kamal: true,
                       push: true, docker: true, db_backup: true)

      aggregate_failures do
        expect_generator_options(Develoz::Generators::FrontendCoreGenerator, tmp, skip_pagy: true)
        expect_generator_options(Develoz::Generators::AdminGenerator, tmp, ui: true)
        expect_generator_options(Develoz::Generators::KamalGenerator, tmp, push: true)
        expect_generator_options(Develoz::Generators::DbBackupGenerator, tmp, docker: true)
      end
    end
  end

  it "warns when a generator is not yet available" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      result = nil
      expect { result = gen.send(:invoke_generator, "nonexistent", {}) }.to output(/not yet available/).to_stdout
      expect(result).to be(false)
    end
  end

  it "warns when the generator file does not define the expected class" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      allow(gen).to receive(:require).and_return(true)
      result = nil
      expect { result = gen.send(:invoke_generator, "missing", {}) }.to output(/not yet available/).to_stdout
      expect(result).to be(false)
    end
  end

  it "reraises unrelated name errors while loading a generator" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      allow(gen).to receive(:require).and_raise(NameError.new("unexpected", :UnexpectedConstant))
      expect { gen.send(:invoke_generator, "missing", {}) }.to raise_error(NameError, /unexpected/)
    end
  end
end
