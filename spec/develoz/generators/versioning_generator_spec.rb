# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/versioning/versioning_generator"

RSpec.describe Develoz::Generators::VersioningGenerator do
  def constants_fixture
    <<~'RUBY'
      # frozen_string_literal: true

      module Constants
        def self.fetch_required(key)
          ENV.fetch(key) { raise "Missing required environment variable: #{key}" }
        end

        APP_NAME = ENV.fetch("APP_NAME", "test_app")

        # additional constants appended by generators
      end
    RUBY
  end

  def with_tmp_dir(&)
    Dir.mktmpdir(&)
  end

  def seed_constants(dir)
    FileUtils.mkdir_p(File.join(dir, "config/initializers"))
    File.write(File.join(dir, "config/initializers/constants.rb"), constants_fixture)
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.inject_app_version_constant
    gen.create_application_helper
    gen.create_app_version_partial
    gen.create_application_helper_spec
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "injects APP_VERSION into constants.rb after the marker" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      constants = File.read(File.join(tmp, "config/initializers/constants.rb"))
      expect(constants).to include('APP_VERSION = ENV.fetch("APP_VERSION", "dev")')
      expect(constants).to include("APP_VERSION = Constants::APP_VERSION")
      expect(constants).to include("# additional constants appended by generators")
    end
  end

  it "places APP_VERSION after the marker comment" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      constants = File.read(File.join(tmp, "config/initializers/constants.rb"))
      marker_pos = constants.index("# additional constants appended by generators")
      version_pos = constants.index('APP_VERSION = ENV.fetch("APP_VERSION", "dev")')
      expect(version_pos).to be > marker_pos
    end
  end

  it "is idempotent for APP_VERSION injection" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      run_gen(tmp)
      constants = File.read(File.join(tmp, "config/initializers/constants.rb"))
      expect(constants.scan('APP_VERSION = ENV.fetch("APP_VERSION", "dev")').size).to eq(1)
      expect(constants.scan("APP_VERSION = Constants::APP_VERSION").size).to eq(1)
    end
  end

  it "creates application_helper.rb when it does not exist" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      helper = File.read(File.join(tmp, "app/helpers/application_helper.rb"))
      expect(helper).to include("module ApplicationHelper")
      expect(helper).to include("def app_version")
      expect(helper).to include("APP_VERSION")
    end
  end

  it "creates application_helper.rb with frozen_string_literal" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      helper = File.read(File.join(tmp, "app/helpers/application_helper.rb"))
      expect(helper).to start_with("# frozen_string_literal: true")
    end
  end

  it "injects app_version method into existing application_helper.rb" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      FileUtils.mkdir_p(File.join(tmp, "app/helpers"))
      File.write(File.join(tmp, "app/helpers/application_helper.rb"), <<~RUBY)
        # frozen_string_literal: true

        module ApplicationHelper
          def existing_method
            "existing"
          end
        end
      RUBY
      run_gen(tmp)
      helper = File.read(File.join(tmp, "app/helpers/application_helper.rb"))
      expect(helper).to include("def existing_method")
      expect(helper).to include("def app_version")
      expect(helper).to include("APP_VERSION")
    end
  end

  it "is idempotent for application_helper.rb injection" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      FileUtils.mkdir_p(File.join(tmp, "app/helpers"))
      File.write(File.join(tmp, "app/helpers/application_helper.rb"), <<~RUBY)
        # frozen_string_literal: true

        module ApplicationHelper
          def existing_method
            "existing"
          end
        end
      RUBY
      run_gen(tmp)
      run_gen(tmp)
      helper = File.read(File.join(tmp, "app/helpers/application_helper.rb"))
      expect(helper.scan("def app_version").size).to eq(1)
    end
  end

  it "is idempotent for application_helper.rb creation" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/helpers/application_helper.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/helpers/application_helper.rb"))
      expect(first).to eq(second)
    end
  end

  it "creates the application helper spec" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/helpers/application_helper_spec.rb"))
    end
  end

  it "creates the _app_version partial" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/shared/_app_version.html.erb"))
    end
  end

  it "partial renders app_version when present" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      partial = File.read(File.join(tmp, "app/views/shared/_app_version.html.erb"))
      expect(partial).to include("app_version.present?")
      expect(partial).to include("<%= app_version %>")
    end
  end

  it "is idempotent for partial creation" do
    with_tmp_dir do |tmp|
      seed_constants(tmp)
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/shared/_app_version.html.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/shared/_app_version.html.erb"))
      expect(first).to eq(second)
    end
  end
end
