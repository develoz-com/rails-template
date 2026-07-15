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
    gen.install
    gen
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
      expect { gen.send(:invoke_generator, "nonexistent", {}) }.to output(/not yet available/).to_stdout
    end
  end

  it "warns when the generator file does not define the expected class" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      allow(gen).to receive(:require).and_return(true)
      expect { gen.send(:invoke_generator, "missing", {}) }.to output(/not yet available/).to_stdout
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
