# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/testing/testing_generator"

RSpec.describe Develoz::Generators::TestingGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      # seed a minimal app so add_gem has a target
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.add_test_gems
    gen.create_rspec_config
    gen.create_spec_helper
    gen.create_rails_helper
    gen.create_rspec_parallel_config
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds rspec-rails gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("rspec-rails")
    end
  end

  it "adds capybara gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("capybara")
    end
  end

  it "adds selenium-webdriver gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("selenium-webdriver")
    end
  end

  it "adds simplecov gem with require: false" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("simplecov")
    end
  end

  it "adds simplecov-lcov gem with require: false" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("simplecov-lcov")
    end
  end

  it "adds parallel_tests gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("parallel_tests")
    end
  end

  it "adds factory_bot_rails gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("factory_bot_rails")
    end
  end

  it "generates .rspec file" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".rspec"))
    end
  end

  it "generates .rspec with correct format" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rspec_content = File.read(File.join(tmp, ".rspec"))
      expect(rspec_content).to include("--require spec_helper")
      expect(rspec_content).to include("--format documentation")
    end
  end

  it "generates .rspec_parallel file" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".rspec_parallel"))
    end
  end

  it "generates .rspec_parallel with correct format" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rspec_parallel_content = File.read(File.join(tmp, ".rspec_parallel"))
      expect(rspec_parallel_content).to include("--require spec_helper")
      expect(rspec_parallel_content).to include("--format documentation")
    end
  end

  it "generates spec/spec_helper.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/spec_helper.rb"))
    end
  end

  it "generates spec_helper with SimpleCov configuration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      spec_helper = File.read(File.join(tmp, "spec/spec_helper.rb"))
      expect(spec_helper).to include("require \"simplecov\"")
      expect(spec_helper).to include("enable_coverage :branch")
      expect(spec_helper).to include("minimum_coverage line: 100, branch: 100")
    end
  end

  it "generates spec_helper with public/coverage directory" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      spec_helper = File.read(File.join(tmp, "spec/spec_helper.rb"))
      expect(spec_helper).to include('coverage_dir "public/coverage"')
    end
  end

  it "generates spec_helper with parallel test collation" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      spec_helper = File.read(File.join(tmp, "spec/spec_helper.rb"))
      expect(spec_helper).to include("TEST_ENV_NUMBER")
      expect(spec_helper).to include("use_merging true")
    end
  end

  it "generates spec_helper with filter configuration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      spec_helper = File.read(File.join(tmp, "spec/spec_helper.rb"))
      expect(spec_helper).to include("add_filter %w[/spec/ /config/ /db/]")
    end
  end

  it "generates spec/rails_helper.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/rails_helper.rb"))
    end
  end

  it "generates rails_helper with spec_helper require" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("require \"spec_helper\"")
    end
  end

  it "generates rails_helper with rails/rspec require" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("require \"rails/rspec\"")
    end
  end

  it "generates rails_helper with Capybara driver registration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("Capybara.register_driver :headless_chrome")
      expect(rails_helper).to include("--headless=new")
    end
  end

  it "generates rails_helper with Chrome headless options" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("--no-sandbox")
      expect(rails_helper).to include("--disable-gpu")
    end
  end

  it "generates rails_helper with Capybara javascript driver" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("Capybara.javascript_driver = :headless_chrome")
    end
  end

  it "generates rails_helper with FactoryBot configuration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("FactoryBot.definition_file_paths")
      expect(rails_helper).to include("FactoryBot.find_definitions")
    end
  end

  it "generates rails_helper with ActiveRecord migration schema maintenance" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("ActiveRecord::Migration.maintain_test_schema!")
    end
  end

  it "is idempotent for gems" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("rspec-rails").size).to eq(1)
      expect(gemfile.scan("capybara").size).to eq(1)
      expect(gemfile.scan("selenium-webdriver").size).to eq(1)
    end
  end

  it "is idempotent for .rspec file" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, ".rspec"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, ".rspec"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for spec_helper.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "spec/spec_helper.rb"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "spec/spec_helper.rb"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for rails_helper.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "spec/rails_helper.rb"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(first_content).to eq(second_content)
    end
  end

  it "generates rspec config files" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".rspec"))
      expect(File).to exist(File.join(tmp, ".rspec_parallel"))
    end
  end

  it "generates spec helper files" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/spec_helper.rb"))
      expect(File).to exist(File.join(tmp, "spec/rails_helper.rb"))
    end
  end

  it "spec_helper has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      spec_helper = File.read(File.join(tmp, "spec/spec_helper.rb"))
      expect(spec_helper).to start_with("# frozen_string_literal: true")
    end
  end

  it "rails_helper has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to start_with("# frozen_string_literal: true")
    end
  end

  it "spec_helper includes SimpleCov formatters" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      spec_helper = File.read(File.join(tmp, "spec/spec_helper.rb"))
      expect(spec_helper).to include("SimpleCov::Formatter::HTMLFormatter")
      expect(spec_helper).to include("SimpleCov::Formatter::LcovFormatter")
    end
  end

  it "rails_helper includes support files loading" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("spec/support/**/*.rb")
    end
  end

  it "rails_helper includes fixture path configuration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("config.fixture_path")
    end
  end

  it "rails_helper includes transactional fixtures" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("config.use_transactional_fixtures = true")
    end
  end

  it "rails_helper includes spec type inference" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("config.infer_spec_type_from_file_location!")
    end
  end

  it "rails_helper filters rails from backtrace" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rails_helper = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(rails_helper).to include("config.filter_rails_from_backtrace!")
    end
  end
end
