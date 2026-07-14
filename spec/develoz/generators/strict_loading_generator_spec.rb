# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/strict_loading/strict_loading_generator"

RSpec.describe Develoz::Generators::StrictLoadingGenerator do
  # rubocop:disable Style/ExplicitBlockArgument
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      yield dir
    end
  end
  # rubocop:enable Style/ExplicitBlockArgument

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.create_strict_loading_initializer
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "generates config/initializers/strict_loading.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/strict_loading.rb"))
    end
  end

  it "has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/strict_loading.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "enables strict_loading_by_default" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/strict_loading.rb"))
      expect(content).to include("strict_loading_by_default = true")
    end
  end

  it "sets strict_loading_mode to n_plus_one_only" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/strict_loading.rb"))
      expect(content).to include("strict_loading_mode = :n_plus_one_only")
    end
  end

  it "raises violations in test environment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/strict_loading.rb"))
      expect(content).to include('when "test" then :raise')
    end
  end

  it "logs violations in development and production" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/strict_loading.rb"))
      expect(content).to include("else :log")
    end
  end

  it "configures strict_loading_violation" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/initializers/strict_loading.rb"))
      expect(content).to include("strict_loading_violation")
    end
  end

  it "is idempotent" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/initializers/strict_loading.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/initializers/strict_loading.rb"))
      expect(first).to eq(second)
    end
  end
end
