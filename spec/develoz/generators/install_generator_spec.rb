# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/install/install_generator"

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

  it "warns when a generator is not yet available" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      expect { gen.send(:invoke_generator, "api") }.to output(/not yet available/).to_stdout
    end
  end
end
