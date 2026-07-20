# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Develoz::Generators::FeatureDocumentation do
  subject(:documentation) { described_class.new(generator) }

  let(:generator_class) do
    Class.new(Develoz::Generators::Base) do
      def self.source_root
        File.expand_path("../../fixtures/feature_documentation/templates", __dir__)
      end

      def self.feature_name
        "testing"
      end
    end
  end
  let(:generator) { generator_class.new([], {}, destination_root: destination_root) }

  let(:destination_root) { Dir.mktmpdir }

  after { FileUtils.remove_entry(destination_root) }

  def read(path)
    File.binread(File.join(destination_root, path))
  end

  def write(path, content)
    absolute_path = File.join(destination_root, path)
    FileUtils.mkdir_p(File.dirname(absolute_path))
    File.binwrite(absolute_path, content)
  end

  it "renders the generator-local documentation template to its direct docs path" do
    documentation.render

    expected = "# Testing Feature\n\nGenerated for #{File.basename(destination_root)}.\n"

    expect(read("docs/testing-feature.md")).to eq(expected)
  end

  it "does not overwrite conflicting feature documentation" do
    write("docs/testing-feature.md", "user documentation\n")

    expect { documentation.render }
      .to raise_error(Develoz::Error, %r{docs/testing-feature\.md already exists with different content})
    expect(read("docs/testing-feature.md")).to eq("user documentation\n")
  end

  it "accepts an existing feature document with identical content" do
    documentation.render
    original = read("docs/testing-feature.md")

    expect { documentation.render }.not_to raise_error
    expect(read("docs/testing-feature.md")).to eq(original)
  end

  it "raises when its generator-local template is missing" do
    allow(generator_class).to receive(:source_root).and_return(File.join(destination_root, "missing"))

    expect { documentation.render }
      .to raise_error(Develoz::Error, /Missing feature documentation template for testing: .*testing-feature\.md\.tt/)
    expect(File).not_to exist(File.join(destination_root, "docs/testing-feature.md"))
  end

  it "additively reconciles links in manifest order and preserves surrounding bytes" do
    original = "# App\r\n\r\nUser prose without a final newline"
    write("README.md", original)
    entries = [Develoz::Manifest.fetch("push"), Develoz::Manifest.fetch("testing")]

    described_class.reconcile(destination_root:, entries:, mode: :additive)

    expect(read("README.md")).to start_with(original)
    expect(read("README.md").index("Testing")).to be < read("README.md").index("Push Notifications")
  end

  it "retains existing managed links in additive mode" do
    described_class.reconcile(destination_root:, entries: [Develoz::Manifest.fetch("api")], mode: :additive)
    described_class.reconcile(destination_root:, entries: [Develoz::Manifest.fetch("auth")], mode: :additive)

    expect(read("README.md")).to include("docs/api.md", "docs/auth.md")
  end

  it "rejects unknown managed documentation links without changing either managed file" do
    described_class.reconcile(destination_root:, entries: [Develoz::Manifest.fetch("api")], mode: :additive)
    unknown_link = "- [Unknown](docs/unknown.md)\n"
    readme = read("README.md").sub(described_class::END_MARKER, "#{unknown_link}#{described_class::END_MARKER}")
    write("README.md", readme)
    before = %w[README.md AGENTS.md].index_with { |path| read(path) }

    expect do
      described_class.reconcile(destination_root:, entries: [Develoz::Manifest.fetch("auth")], mode: :additive)
    end.to raise_error(Develoz::Error, %r{README\.md.*unknown feature documentation link: docs/unknown\.md})

    expect(%w[README.md AGENTS.md].index_with { |path| read(path) }).to eq(before)
  end

  it "removes unselected managed links in authoritative mode" do
    described_class.reconcile(destination_root:, entries: [Develoz::Manifest.fetch("api")], mode: :additive)
    described_class.reconcile(destination_root:, entries: [Develoz::Manifest.fetch("auth")], mode: :authoritative)

    expect(read("README.md")).to include("docs/auth.md")
    expect(read("README.md")).not_to include("docs/api.md")
  end

  it "replaces exactly one managed block without changing bytes outside it" do
    prefix = "# App\r\ncustom-before\r\n"
    suffix = "\r\ncustom-after\r\n"
    old_block = <<~BLOCK.chomp
      <!-- BEGIN DEVELOZ FEATURE DOCUMENTATION -->
      ## Feature Documentation

      - [Old](docs/old.md)
      <!-- END DEVELOZ FEATURE DOCUMENTATION -->
    BLOCK
    write("AGENTS.md", "#{prefix}#{old_block}#{suffix}")

    described_class.reconcile(destination_root:, entries: [Develoz::Manifest.fetch("api")], mode: :authoritative)

    expect(read("AGENTS.md")).to start_with(prefix)
    expect(read("AGENTS.md")).to end_with(suffix)
    expect(read("AGENTS.md")).to include("docs/api.md")
  end

  it "raises a descriptive error for missing, reversed, or duplicate markers" do
    malformed = [
      "<!-- BEGIN DEVELOZ FEATURE DOCUMENTATION -->",
      "<!-- END DEVELOZ FEATURE DOCUMENTATION -->\n<!-- BEGIN DEVELOZ FEATURE DOCUMENTATION -->",
      "<!-- BEGIN DEVELOZ FEATURE DOCUMENTATION -->\n" \
      "<!-- BEGIN DEVELOZ FEATURE DOCUMENTATION -->\n" \
      "<!-- END DEVELOZ FEATURE DOCUMENTATION -->"
    ]

    malformed.each do |content|
      write("README.md", content)
      expect do
        described_class.reconcile(destination_root:, entries: [], mode: :authoritative)
      end.to raise_error(Develoz::Error, /README\.md has malformed Develoz feature documentation markers/)
    end
  end

  it "creates minimal README and AGENTS scaffolds when either file is absent" do
    described_class.reconcile(destination_root:, entries: [Develoz::Manifest.fetch("testing")], mode: :authoritative)

    aggregate_failures do
      expect(read("README.md")).to start_with("# #{File.basename(destination_root)}\n\n")
      expect(read("AGENTS.md")).to start_with("# AGENTS.md\n\n")
      expect(read("README.md").scan(described_class::BEGIN_MARKER).size).to eq(1)
      expect(read("AGENTS.md").scan(described_class::END_MARKER).size).to eq(1)
    end
  end

  it "rejects unknown reconciliation modes" do
    expect do
      described_class.reconcile(destination_root:, entries: [], mode: :replace)
    end.to raise_error(ArgumentError, /Unknown feature documentation reconciliation mode: :replace/)
  end
end
