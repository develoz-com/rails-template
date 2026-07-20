# frozen_string_literal: true

require "tmpdir"

RSpec.describe Develoz::Manifest do
  def expect_documentation_parity(entry, destination_root)
    rendered = render_documentation(entry, destination_root)

    aggregate_failures(entry.name) do
      expect_generator_artifacts(entry)
      expect(rendered.lines.first.chomp).to eq("# #{entry.documentation_title}")
      expect(rendered).to include(*required_documentation_sections)
      expect_document_format(rendered)
    end
  end

  def render_documentation(entry, destination_root)
    generator_class = Develoz::Generators.const_get("#{entry.name.camelize}Generator")
    generator = generator_class.new([], {}, destination_root:)
    Develoz::Generators::FeatureDocumentation.new(generator).render
    File.binread(File.join(destination_root, "docs/#{entry.documentation_slug}.md"))
  end

  def expect_generator_artifacts(entry)
    expect(File).to exist(local_generator_file(entry))
    expect_template_artifact(entry)
  end

  def expect_template_artifact(entry)
    generator_class = Develoz::Generators.const_get("#{entry.name.camelize}Generator")
    template_path = File.join(generator_class.source_root, "docs/#{entry.documentation_slug}.md.tt")

    expect(template_path).to eq(local_template_file(entry))
    expect(File).to exist(template_path)
  end

  def local_generator_file(entry)
    File.expand_path("../../lib/generators/develoz/#{entry.name}/#{entry.name}_generator.rb", __dir__)
  end

  def local_template_file(entry)
    relative_path = "../../lib/generators/develoz/#{entry.name}/templates/docs/" \
                    "#{entry.documentation_slug}.md.tt"
    File.expand_path(relative_path, __dir__)
  end

  def expect_document_format(rendered)
    expect(rendered).to be_ascii_only
    expect(rendered).to end_with("\n")
  end

  def required_documentation_sections
    ["Overview", "What It Adds", "Configuration", "Usage", "Verification"].map { |section| "## #{section}" }
  end

  describe ".load" do
    it "loads the manifest from config/generators.yml" do
      manifest = described_class.load
      expect(manifest).to be_a(Hash)
    end

    it "includes always-core generators" do
      manifest = described_class.load
      expect(manifest).to have_key("tooling")
      expect(manifest["tooling"]).to have_key("always")
      expect(manifest["tooling"]["always"]).to be true
    end

    it "includes opt-in generators" do
      manifest = described_class.load
      expect(manifest).to have_key("api")
      expect(manifest["api"]).to have_key("requires")
    end

    it "includes descriptions for all generators" do
      manifest = described_class.load
      manifest.each_value do |config|
        expect(config).to have_key("description")
      end
    end

    it "includes valid, unique documentation metadata for all 23 generators" do
      manifest = described_class.load
      slugs = manifest.values.map { |config| config.fetch("documentation_slug") }

      aggregate_failures do
        expect(manifest.size).to eq(23)
        expect(slugs).to all(match(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/))
        expect(slugs.uniq).to eq(slugs)
        expect(manifest.values).to all(satisfy { |config| config.fetch("documentation_title").match?(/\S/) })
      end
    end

    it "uses a collision-free direct documentation path for testing" do
      expect(described_class.fetch("testing").documentation_slug).to eq("testing-feature")
    end

    it "rejects duplicate documentation slugs" do
      manifest = {
        "first" => { "documentation_slug" => "shared", "documentation_title" => "First" },
        "second" => { "documentation_slug" => "shared", "documentation_title" => "Second" }
      }

      expect { described_class.send(:validate!, manifest) }
        .to raise_error(Develoz::Error, /Duplicate documentation slug\(s\): shared/)
    end

    it "rejects missing or malformed documentation metadata" do
      manifest = { "invalid" => { "documentation_slug" => "Not Valid", "documentation_title" => "" } }

      expect { described_class.send(:validate!, manifest) }
        .to raise_error(Develoz::Error, /invalid must define a valid documentation_slug and documentation_title/)
    end

    it "keeps every manifest entry in parity with its generator and feature guide" do
      Dir.mktmpdir do |destination_root|
        entries = described_class.all
        entries.each { |entry| expect_documentation_parity(entry, destination_root) }
      end
    end
  end

  describe ".for" do
    it "returns an array of Entry objects" do
      options = Develoz::Options.new
      entries = described_class.for(options)
      expect(entries).to be_an(Array)
      expect(entries.first).to be_a(described_class::Entry)
    end

    it "includes all always-core generators" do
      options = Develoz::Options.new
      entries = described_class.for(options)
      names = entries.map(&:name)

      core_generators = %w[
        tooling testing solid ci database concerns strict_loading maintenance
        frontend_core docs_render doc_specs agents_docs versioning
      ]
      core_generators.each { |gen| expect(names).to include(gen) }
    end

    it "excludes opt-in generators when flags are false" do
      options = Develoz::Options.new(api: false, auth: false)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).not_to include("api")
      expect(names).not_to include("auth")
    end

    it "includes api generator when api flag is true" do
      options = Develoz::Options.new(api: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("api")
    end

    it "includes auth generator when auth flag is true" do
      options = Develoz::Options.new(auth: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("auth")
    end

    it "includes ui generator when ui flag is true" do
      options = Develoz::Options.new(ui: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("ui")
    end

    it "includes admin generator when admin flag is true" do
      options = Develoz::Options.new(admin: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("admin")
    end

    it "includes pwa generator when pwa flag is true" do
      options = Develoz::Options.new(pwa: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("pwa")
    end

    it "includes active_resource generator when active_resource flag is true" do
      options = Develoz::Options.new(active_resource: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("active_resource")
    end

    it "includes docker generator when docker flag is true" do
      options = Develoz::Options.new(docker: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("docker")
    end

    it "includes kamal generator when kamal flag is true" do
      options = Develoz::Options.new(kamal: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("kamal")
    end

    it "includes db_backup generator when db_backup flag is true" do
      options = Develoz::Options.new(db_backup: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("db_backup")
    end

    it "includes push generator when both pwa and push flags are true" do
      options = Develoz::Options.new(pwa: true, push: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("push")
    end

    it "includes push generator when pwa is false and push is true (auto-includes pwa)" do
      options = Develoz::Options.new(pwa: false, push: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      # Push should be included because pwa is auto-included
      expect(names).to include("push")
    end

    it "auto-includes pwa when push is true but pwa is false" do
      options = Develoz::Options.new(pwa: false, push: true)
      expect(options.pwa?).to be false

      described_class.for(options)

      expect(options.pwa?).to be true
    end

    it "includes pwa generator after auto-include" do
      options = Develoz::Options.new(pwa: false, push: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("pwa")
    end

    it "returns entries in stable order (always-core first, then opt-in)" do
      options = Develoz::Options.new(api: true, auth: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      # Always-core should come before opt-in
      tooling_idx = names.index("tooling")
      api_idx = names.index("api")
      expect(tooling_idx).to be < api_idx
    end

    it "exposes name, description, and documentation metadata on each entry" do
      options = Develoz::Options.new(api: true)
      entries = described_class.for(options)
      api_entry = entries.find { |e| e.name == "api" }

      aggregate_failures do
        expect(api_entry.name).to eq("api")
        expect(api_entry.description).to be_a(String)
        expect(api_entry.description).not_to be_empty
        expect(api_entry.documentation_slug).to eq("api")
        expect(api_entry.documentation_title).to eq("API")
      end
    end

    it "handles multiple opt-in flags correctly" do
      options = Develoz::Options.new(api: true, auth: true, ui: true, admin: true)
      entries = described_class.for(options)
      names = entries.map(&:name)

      %w[api auth ui admin].each { |gen| expect(names).to include(gen) }
    end

    it "does not include generators whose requires are not all met" do
      options = Develoz::Options.new(pwa: true, push: false)
      entries = described_class.for(options)
      names = entries.map(&:name)

      expect(names).to include("pwa")
      expect(names).not_to include("push")
    end

    it "includes all always-core generators even with no opt-in flags" do
      options = Develoz::Options.new
      entries = described_class.for(options)
      names = entries.map(&:name)

      # Verify at least the core ones are present
      expect(names.length).to be >= 13
      expect(names).to include("tooling")
      expect(names).to include("frontend_core")
    end
  end

  describe "Entry struct" do
    it "has name, description, documentation slug, and documentation title attributes" do
      entry = described_class::Entry.new("test_gen", "Test generator", "test-gen", "Test Generator")
      aggregate_failures do
        expect(entry.name).to eq("test_gen")
        expect(entry.description).to eq("Test generator")
        expect(entry.documentation_slug).to eq("test-gen")
        expect(entry.documentation_title).to eq("Test Generator")
      end
    end
  end
end
