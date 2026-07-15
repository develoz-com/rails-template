# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/tooling/tooling_generator"

RSpec.describe Develoz::Generators::ToolingGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      # seed a minimal app so add_gem/ensure_gitignore have targets
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      File.write(File.join(dir, ".gitignore"), "/log\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.create_vscode
    gen.create_env_files
    gen.create_constants
    gen.add_dotenv
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "generates vscode files" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".vscode/settings.json"))
      expect(File).to exist(File.join(tmp, ".vscode/extensions.json"))
      expect(File).to exist(File.join(tmp, ".vscode/tasks.json"))
    end
  end

  it "generates env files" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".env.example"))
      expect(File).to exist(File.join(tmp, ".env"))
    end
  end

  it "generates config files with correct content" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File.read(File.join(tmp, "config/initializers/constants.rb"))).to include("module Constants")
      expect(File.read(File.join(tmp, "Gemfile"))).to include("dotenv-rails")
      expect(File.read(File.join(tmp, ".gitignore"))).to include(".env")
    end
  end

  it "is idempotent" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      expect(File.read(File.join(tmp, "Gemfile")).scan("dotenv-rails").size).to eq(1)
      expect(File.read(File.join(tmp, ".gitignore")).scan(/^\.env$/).size).to eq(1)
    end
  end

  it "creates .env file if it does not exist" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env_path = File.join(tmp, ".env")
      expect(File).to exist(env_path)
      expect(File.read(env_path)).to eq("")
    end
  end

  it "does not overwrite .env if it already exists" do
    with_tmp_dir do |tmp|
      existing_env = File.join(tmp, ".env")
      File.write(existing_env, "EXISTING_KEY=value\n")

      run_gen(tmp)
      content = File.read(existing_env)
      expect(content).to include("EXISTING_KEY=value")
    end
  end

  it "generates vscode settings with ruby-lsp formatter" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      settings = File.read(File.join(tmp, ".vscode/settings.json"))
      expect(settings).to include("Shopify.ruby-lsp")
      expect(settings).to include("formatOnSave")
    end
  end

  it "generates vscode extensions with recommendations" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      extensions = File.read(File.join(tmp, ".vscode/extensions.json"))
      expect(extensions).to include("Shopify.ruby-lsp")
      expect(extensions).to include("EditorConfig.EditorConfig")
    end
  end

  it "generates vscode tasks for rspec and rubocop" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      tasks = File.read(File.join(tmp, ".vscode/tasks.json"))
      expect(tasks).to include("rspec")
      expect(tasks).to include("rubocop")
    end
  end

  it "generates env.example with app_name" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env_example = File.read(File.join(tmp, ".env.example"))
      expect(env_example).to include("APP_NAME=")
      expect(env_example).to include(File.basename(tmp))
    end
  end

  it "generates constants module with direct ENV.fetch declarations" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      constants = File.read(File.join(tmp, "config/initializers/constants.rb"))
      expect(constants).to include("APP_NAME = ENV.fetch('APP_NAME',")
      expect(constants).to include("APP_NAME")
      expect(constants).to include("# additional constants appended by generators")
    end
  end

  it "adds dotenv-rails gem to Gemfile" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("dotenv-rails")
    end
  end

  it "adds .env to .gitignore" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gitignore = File.read(File.join(tmp, ".gitignore"))
      expect(gitignore).to include(".env")
    end
  end
end
