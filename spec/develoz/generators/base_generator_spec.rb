# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Develoz::Generators::Base do
  let(:generator_class) do
    Class.new(described_class) do
      def self.source_root
        File.expand_path("../../fixtures/feature_documentation/templates", __dir__)
      end

      def self.feature_name
        "testing"
      end

      def create_feature
        create_file "feature.txt", "created\n"
      end
    end
  end

  let(:destination_root) { Dir.mktmpdir }

  after { FileUtils.remove_entry(destination_root) }

  it "runs feature documentation after all generator tasks" do
    generator_class.start([], destination_root:)

    expect(File).to exist(File.join(destination_root, "feature.txt"))
    expect(File).to exist(File.join(destination_root, "docs/testing-feature.md"))
    expect(File.read(File.join(destination_root, "README.md"))).to include("docs/testing-feature.md")
  end

  it "can defer link reconciliation while still rendering the feature document" do
    generator = generator_class.new([], {}, destination_root:)
    generator.defer_feature_documentation!
    generator.invoke_all

    expect(File).to exist(File.join(destination_root, "docs/testing-feature.md"))
    expect(File).not_to exist(File.join(destination_root, "README.md"))
  end

  it "does not expose production helpers as Thor tasks" do
    helper_names = %w[defer_feature_documentation! feature_documentation_deferred? document_feature]

    expect(described_class.all_tasks.keys).not_to include(*helper_names)
    expect(generator_class.all_tasks.keys).to eq(["create_feature"])
  end

  describe "#add_gem" do
    let(:gemfile_path) { File.join(destination_root, "Gemfile") }

    before do
      File.write(gemfile_path, <<~RUBY)
        source "https://rubygems.org"
        gem "rails"

        group :development, :test do
          gem "rspec"
        end

        group :development do
          gem "web-console"
        end

        group :test do
          gem "capybara"
        end
      RUBY
    end

    it "skips adding if already present" do
      generator = generator_class.new([], {}, destination_root:)
      expect { generator.add_gem("rails") }.to output(/already present/).to_stdout
    end

    it "adds gem to existing development, test group" do
      generator = generator_class.new([], {}, destination_root:)
      generator.add_gem("reek", group: %i[development test])
      content = File.read(gemfile_path)
      expect(content).to include("  gem \"reek\"\nend")
      expect(content.scan("reek").size).to eq(1)
    end

    it "adds gem with options to existing development group" do
      generator = generator_class.new([], {}, destination_root:)
      generator.add_gem("brakeman", group: :development, require: false)
      content = File.read(gemfile_path)
      expect(content).to include("  gem \"brakeman\", require: false\nend")
    end

    it "adds gem with version to existing test group" do
      generator = generator_class.new([], {}, destination_root:)
      generator.add_gem("simplecov", "1.0.0", group: :test)
      content = File.read(gemfile_path)
      expect(content).to include("  gem \"simplecov\", \"1.0.0\"\nend")
    end

    it "falls back to standard gem injection if group block is not found" do
      generator = generator_class.new([], {}, destination_root:)
      generator.add_gem("maintenance_tasks", group: :production)
      content = File.read(gemfile_path)
      expect(content).to include('gem "maintenance_tasks", group: :production')
    end

    it "falls back to standard gem injection if group block is matched but has no closing end" do
      File.write(gemfile_path, <<~RUBY)
        source "https://rubygems.org"
        group :development, :test do
          gem "rspec"
      RUBY
      generator = generator_class.new([], {}, destination_root:)
      generator.add_gem("reek", group: %i[development test])
      content = File.read(gemfile_path)
      expect(content).to include('gem "reek", group: [ :development, :test ]')
    end
  end

  describe "#insert_route" do
    it "does nothing if config/routes.rb does not exist" do
      generator = generator_class.new([], {}, destination_root:)
      expect(generator.insert_route("resources :laps")).to be(false)
    end

    it "injects route if config/routes.rb exists" do
      routes_path = File.join(destination_root, "config/routes.rb")
      FileUtils.mkdir_p(File.dirname(routes_path))
      File.write(routes_path, "Rails.application.routes.draw do\nend\n")

      generator = generator_class.new([], {}, destination_root:)
      generator.insert_route("resources :laps")
      expect(File.read(routes_path)).to include("  resources :laps")
    end
  end
end
