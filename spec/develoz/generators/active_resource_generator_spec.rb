# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/active_resource/active_resource_generator"

RSpec.describe Develoz::Generators::ActiveResourceGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.add_activeresource_gem
    gen.create_application_resource
    gen.create_example_resource
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds activeresource gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("activeresource")
    end
  end

  it "generates application_resource.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/application_resource.rb"))
    end
  end

  it "application_resource inherits from ActiveResource::Base" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/application_resource.rb"))
      expect(content).to include("ApplicationResource < ActiveResource::Base")
    end
  end

  it "application_resource reads site from ENV" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/application_resource.rb"))
      expect(content).to include('ENV.fetch("ACTIVE_RESOURCE_SITE"')
    end
  end

  it "application_resource reads authorization header from ENV" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/application_resource.rb"))
      expect(content).to include('ENV.fetch("ACTIVE_RESOURCE_AUTHORIZATION"')
    end
  end

  it "application_resource sets Accept header to application/json" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/application_resource.rb"))
      expect(content).to include('"Accept"')
      expect(content).to include("application/json")
    end
  end

  it "application_resource has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/application_resource.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "does not hardcode a remote site URL" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/application_resource.rb"))
      expect(content).not_to match(%r{https?://[a-z0-9.]+}i)
    end
  end

  it "generates example_resource.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/example_resource.rb"))
    end
  end

  it "example_resource inherits from ApplicationResource" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/example_resource.rb"))
      expect(content).to include("ExampleResource < ApplicationResource")
    end
  end

  it "example_resource has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/example_resource.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "is idempotent for activeresource gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan(/^\s*gem\s+["']activeresource["']/m).length).to eq(1)
    end
  end

  it "is idempotent for application_resource" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/models/application_resource.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/models/application_resource.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for example_resource" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/models/example_resource.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/models/example_resource.rb"))
      expect(first).to eq(second)
    end
  end
end
