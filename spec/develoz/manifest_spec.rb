# frozen_string_literal: true

RSpec.describe Develoz::Manifest do
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

    it "exposes name and description on each entry" do
      options = Develoz::Options.new(api: true)
      entries = described_class.for(options)
      api_entry = entries.find { |e| e.name == "api" }

      expect(api_entry.name).to eq("api")
      expect(api_entry.description).to be_a(String)
      expect(api_entry.description).not_to be_empty
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
    it "has name and description attributes" do
      entry = described_class::Entry.new("test_gen", "Test generator")
      expect(entry.name).to eq("test_gen")
      expect(entry.description).to eq("Test generator")
    end
  end
end
