# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/frontend_core/frontend_core_generator"

RSpec.describe Develoz::Generators::FrontendCoreGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      FileUtils.mkdir_p(File.join(dir, "config"))
      yield dir
    end
  end

  def run_gen(tmp_dir, opts = {})
    gen = described_class.new([], opts, destination_root: tmp_dir)
    gen.add_frontend_gems
    gen.add_pagy_gem
    gen.create_importmap_config
    gen.create_pagy_initializer
    gen.create_annotaterb_config
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds importmap-rails gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("importmap-rails")
    end
  end

  it "adds annotaterb gem in development group" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("annotaterb")
      expect(gemfile).to include("development")
    end
  end

  it "adds pagy gem by default" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("pagy")
    end
  end

  it "does not add pagy gem with skip_pagy" do
    with_tmp_dir do |tmp|
      run_gen(tmp, "skip_pagy" => true)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).not_to include('gem "pagy"')
    end
  end

  it "generates config/importmap.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/importmap.rb"))
    end
  end

  it "importmap has correct pins" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/importmap.rb"))
      expect(content).to include('pin "application"')
      expect(content).to include("@hotwired/turbo-rails")
      expect(content).to include("pin_all_from")
    end
  end

  it "importmap has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/importmap.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates pagy initializer by default" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/pagy.rb"))
    end
  end

  it "does not generate pagy initializer with skip_pagy" do
    with_tmp_dir do |tmp|
      run_gen(tmp, "skip_pagy" => true)
      expect(File).not_to exist(File.join(tmp, "config/initializers/pagy.rb"))
    end
  end

  it "pagy initializer uses built-in pagination features" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/pagy.rb"))
      expect(content).not_to include("pagy/extras")
      expect(content).to include("Pagy::OPTIONS[:limit] = 25")
      expect(content).to include("Pagy::OPTIONS.freeze")
    end
  end

  it "pagy initializer has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/pagy.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates .annotaterb.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".annotaterb.yml"))
    end
  end

  it "annotaterb config enables models and disables routes" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".annotaterb.yml"))
      expect(content).to include(":models: true")
      expect(content).to include(":routes: false")
      expect(content).to include(":active_admin: false")
    end
  end

  it "annotaterb config excludes tests, fixtures, factories, serializers" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".annotaterb.yml"))
      expect(content).to include(":exclude_tests: true")
      expect(content).to include(":exclude_fixtures: true")
      expect(content).to include(":exclude_factories: true")
    end
  end

  it "annotaterb config excludes serializers and scaffolds" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".annotaterb.yml"))
      expect(content).to include(":exclude_serializers: true")
      expect(content).to include(":exclude_scaffolds: true")
    end
  end

  it "annotaterb config is generated with skip_pagy too" do
    with_tmp_dir do |tmp|
      run_gen(tmp, "skip_pagy" => true)
      expect(File).to exist(File.join(tmp, ".annotaterb.yml"))
    end
  end

  it "importmap is generated with skip_pagy too" do
    with_tmp_dir do |tmp|
      run_gen(tmp, "skip_pagy" => true)
      expect(File).to exist(File.join(tmp, "config/importmap.rb"))
    end
  end

  it "is idempotent for gems" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("importmap-rails").size).to eq(1)
      expect(gemfile.scan('"pagy"').size).to eq(1)
      expect(gemfile.scan("annotaterb").size).to eq(1)
    end
  end

  it "is idempotent for importmap" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/importmap.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/importmap.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for pagy initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/initializers/pagy.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/initializers/pagy.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for annotaterb config" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, ".annotaterb.yml"))
      run_gen(tmp)
      second = File.read(File.join(tmp, ".annotaterb.yml"))
      expect(first).to eq(second)
    end
  end
end
