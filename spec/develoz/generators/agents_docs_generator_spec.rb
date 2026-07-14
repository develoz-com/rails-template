# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/agents_docs/agents_docs_generator"

RSpec.describe Develoz::Generators::AgentsDocsGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.add_api_gems
    gen.create_agents_md
    gen.create_docs
    gen.create_pr_template
    gen.create_vcr_support
    gen.create_faraday_support
    gen.create_example_api_spec
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds faraday gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("faraday")
    end
  end

  it "adds faraday-retry gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("faraday-retry")
    end
  end

  it "adds vcr gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("vcr")
    end
  end

  it "adds webmock gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("webmock")
    end
  end

  it "generates AGENTS.md" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "AGENTS.md"))
    end
  end

  it "AGENTS.md has development guidance" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "AGENTS.md"))
      expect(content).to include("Quality Expectations")
    end
  end

  it "AGENTS.md references docs" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "AGENTS.md"))
      expect(content).to include("docs/development.md")
    end
  end

  it "generates docs/development.md" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "docs/development.md"))
    end
  end

  it "docs/development.md has command reference" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docs/development.md"))
      expect(content).to include("Command Reference")
    end
  end

  it "generates docs/testing.md" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "docs/testing.md"))
    end
  end

  it "docs/testing.md has coverage requirement" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docs/testing.md"))
      expect(content).to include("100% line and 100% branch coverage")
    end
  end

  it "generates docs/performance.md" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "docs/performance.md"))
    end
  end

  it "docs/performance.md has N+1 detection" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docs/performance.md"))
      expect(content).to include("N+1 Detection")
    end
  end

  it "generates .github/pull_request_template.md" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".github/pull_request_template.md"))
    end
  end

  it "PR template has Changes section" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".github/pull_request_template.md"))
      expect(content).to include("**Changes:**")
    end
  end

  it "generates spec/support/vcr.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/support/vcr.rb"))
    end
  end

  it "vcr.rb has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/support/vcr.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "vcr.rb configures cassette library dir" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/support/vcr.rb"))
      expect(content).to include("cassette_library_dir")
    end
  end

  it "vcr.rb hooks into webmock" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/support/vcr.rb"))
      expect(content).to include("hook_into :webmock")
    end
  end

  it "generates spec/support/faraday.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/support/faraday.rb"))
    end
  end

  it "faraday.rb has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/support/faraday.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "faraday.rb defines FaradayFactory module" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/support/faraday.rb"))
      expect(content).to include("module FaradayFactory")
    end
  end

  it "faraday.rb configures retry middleware" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/support/faraday.rb"))
      expect(content).to include(":retry")
    end
  end

  it "generates spec/requests/example_api_spec.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/requests/example_api_spec.rb"))
    end
  end

  it "example spec has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/example_api_spec.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "example spec uses VCR metadata" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/example_api_spec.rb"))
      expect(content).to include(":vcr")
    end
  end

  it "example spec uses FaradayFactory" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/example_api_spec.rb"))
      expect(content).to include("FaradayFactory")
    end
  end

  it "generates VCR cassette fixture" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/cassettes/Example_API/fetches_data_from_an_external_API.yml"))
    end
  end

  it "cassette has http_interactions" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/cassettes/Example_API/fetches_data_from_an_external_API.yml"))
      expect(content).to include("http_interactions")
    end
  end

  it "is idempotent for gems" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan(/^\s*gem\s+["']faraday["']/m).length).to eq(1)
    end
  end

  it "is idempotent for AGENTS.md" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "AGENTS.md"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "AGENTS.md"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for docs" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "docs/development.md"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "docs/development.md"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for PR template" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, ".github/pull_request_template.md"))
      run_gen(tmp)
      second = File.read(File.join(tmp, ".github/pull_request_template.md"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for vcr.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/support/vcr.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/support/vcr.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for faraday.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/support/faraday.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/support/faraday.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for example spec" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/requests/example_api_spec.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/requests/example_api_spec.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for cassette" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/cassettes/Example_API/fetches_data_from_an_external_API.yml"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/cassettes/Example_API/fetches_data_from_an_external_API.yml"))
      expect(first).to eq(second)
    end
  end
end
