# frozen_string_literal: true

require "spec_helper"
require "develoz/cli"

RSpec.describe Develoz::CLI do
  let(:resolver) { instance_double(Develoz::VersionResolver) }
  let(:install_gen) { instance_double(Develoz::Generators::InstallGenerator) }

  before do
    allow(Develoz::VersionResolver).to receive(:new).and_return(resolver)
    allow(resolver).to receive(:resolve).and_return({ ruby: "4.0.5", rails: "8.1" })
    allow(resolver).to receive(:write_tool_versions)
    allow(resolver).to receive(:write_ruby_version)
    allow(Develoz::Generators::InstallGenerator).to receive(:new).and_return(install_gen)
    allow(install_gen).to receive(:install)
    allow_any_instance_of(described_class).to receive(:system).and_return(true) # rubocop:disable RSpec/AnyInstance
    allow(Dir).to receive(:chdir).and_yield
  end

  it "prints version" do
    expect { described_class.start(%w[version]) }.to output(/develoz #{Develoz::VERSION}/o).to_stdout
  end

  it "generates app with --yes without prompting" do # rubocop:disable RSpec/MultipleExpectations
    expect { described_class.start(%w[new demo --yes]) }.to output(/Created demo/).to_stdout
    expect(resolver).to have_received(:resolve).with(ruby: nil, rails: nil)
    expect(resolver).to have_received(:write_tool_versions).with(anything, ruby: "4.0.5")
    expect(install_gen).to have_received(:install)
  end

  it "passes --api flag through to install generator" do
    described_class.start(%w[new demo --yes --api])
    expect(Develoz::Generators::InstallGenerator).to have_received(:new)
      .with([], hash_including(api: true), anything)
  end

  it "prompts without --yes" do
    prompt_double = instance_double(TTY::Prompt)
    allow(TTY::Prompt).to receive(:new).and_return(prompt_double)
    allow(prompt_double).to receive(:yes?).and_return(true)
    described_class.start(%w[new demo])
    expect(prompt_double).to have_received(:yes?).at_least(:once)
  end

  it "raises on rails new failure" do
    allow_any_instance_of(described_class).to receive(:system).and_return(false) # rubocop:disable RSpec/AnyInstance
    expect { described_class.start(%w[new demo --yes]) }.to raise_error(/Failed to generate/)
  end
end
