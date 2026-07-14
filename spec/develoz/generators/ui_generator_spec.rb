# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/ui/ui_generator"

RSpec.describe Develoz::Generators::UiGenerator do
  def with_tmp_dir(&)
    Dir.mktmpdir(&)
  end

  def seed_gemfile(dir)
    File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
  end

  def seed_importmap(dir)
    FileUtils.mkdir_p(File.join(dir, "config"))
    File.write(File.join(dir, "config/importmap.rb"), <<~RUBY)
      # frozen_string_literal: true

      pin "application"
      pin_all_from "app/javascript/controllers", under: "controllers"
    RUBY
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.add_develoz_ui_gems
    gen.create_gitmodules
    gen.create_setup_script
    gen.inject_importmap_pins
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "injects develoz_ui gem with path in development/test group" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include('gem "develoz_ui", path: "vendor/develoz-ui"')
      expect(gemfile).to include("group :development, :test")
    end
  end

  it "injects develoz_ui gem with github in production group" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include('gem "develoz_ui", github: "develoz-com/develoz-ui"')
      expect(gemfile).to include("group :production")
    end
  end

  it "is idempotent for Gemfile injection" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan('gem "develoz_ui"').size).to eq(2)
      expect(gemfile.scan("group :development, :test").size).to eq(1)
      expect(gemfile.scan("group :production").size).to eq(1)
    end
  end

  it "creates .gitmodules when it does not exist" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".gitmodules"))
    end
  end

  it "injects submodule section into .gitmodules" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      content = File.read(File.join(tmp, ".gitmodules"))
      expect(content).to include('[submodule "vendor/develoz-ui"]')
      expect(content).to include("path = vendor/develoz-ui")
      expect(content).to include("url = git@github.com:develoz-com/develoz-ui.git")
    end
  end

  it "appends to existing .gitmodules" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      File.write(File.join(tmp, ".gitmodules"),
                 "[submodule \"vendor/other\"]\n\tpath = vendor/other\n" \
                 "\turl = git@github.com:example/other.git\n")
      run_gen(tmp)
      content = File.read(File.join(tmp, ".gitmodules"))
      expect(content).to include('[submodule "vendor/other"]')
      expect(content).to include('[submodule "vendor/develoz-ui"]')
    end
  end

  it "is idempotent for .gitmodules" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      run_gen(tmp)
      content = File.read(File.join(tmp, ".gitmodules"))
      expect(content.scan('[submodule "vendor/develoz-ui"]').size).to eq(1)
    end
  end

  it "creates bin/setup_develoz_ui script" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "bin/setup_develoz_ui"))
    end
  end

  it "makes bin/setup_develoz_ui executable" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      mode = File.stat(File.join(tmp, "bin/setup_develoz_ui")).mode & 0o777
      expect(mode).to eq(0o755)
    end
  end

  it "setup script contains git submodule update command" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/setup_develoz_ui"))
      expect(content).to include("git submodule update --init --recursive")
      expect(content).to include("vendor/develoz-ui")
    end
  end

  it "setup script documents submodule not initialized error" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/setup_develoz_ui"))
      expect(content).to include("not initialized")
    end
  end

  it "is idempotent for setup script" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      first = File.read(File.join(tmp, "bin/setup_develoz_ui"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "bin/setup_develoz_ui"))
      expect(first).to eq(second)
    end
  end

  it "preserves executable bit on re-run" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      run_gen(tmp)
      run_gen(tmp)
      mode = File.stat(File.join(tmp, "bin/setup_develoz_ui")).mode & 0o777
      expect(mode).to eq(0o755)
    end
  end

  it "injects develoz-ui pins into existing importmap" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      seed_importmap(tmp)
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/importmap.rb"))
      expect(content).to include('pin "develoz-ui"')
      expect(content).to include("develoz-ui/controllers")
    end
  end

  it "preserves existing importmap content" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      seed_importmap(tmp)
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/importmap.rb"))
      expect(content).to include('pin "application"')
      expect(content).to include("controllers")
    end
  end

  it "is idempotent for importmap injection" do
    with_tmp_dir do |tmp|
      seed_gemfile(tmp)
      seed_importmap(tmp)
      run_gen(tmp)
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/importmap.rb"))
      expect(content.scan('pin "develoz-ui"').size).to eq(1)
      expect(content.scan("develoz-ui/controllers").size).to eq(1)
    end
  end
end
