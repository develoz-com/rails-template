# frozen_string_literal: true

RSpec.describe Develoz::Options do
  describe "initialization" do
    it "creates an instance with no arguments" do
      options = described_class.new
      expect(options).to be_a(described_class)
    end

    it "accepts opt-in flags" do
      options = described_class.new(api: true, auth: true)
      expect(options.api?).to be true
      expect(options.auth?).to be true
    end

    it "accepts opt-out flags" do
      options = described_class.new(skip_pagy: true)
      expect(options.skip_pagy?).to be true
    end

    it "accepts metadata fields" do
      options = described_class.new(app_name: "demo", ruby_version: "4.0.5", rails_version: "8.1.0")
      expect(options.app_name).to eq("demo")
      expect(options.ruby_version).to eq("4.0.5")
      expect(options.rails_version).to eq("8.1.0")
    end

    it "raises ArgumentError for unknown keys" do
      expect do
        described_class.new(unknown_flag: true)
      end.to raise_error(ArgumentError, /Unknown option\(s\): unknown_flag/)
    end

    it "raises ArgumentError naming multiple unknown keys" do
      expect do
        described_class.new(bad_one: true, bad_two: false)
      end.to raise_error(ArgumentError, /Unknown option\(s\):/)
    end
  end

  describe "opt-in flags (default false)" do
    let(:options) { described_class.new }

    it "defaults api? to false" do
      expect(options.api?).to be false
    end

    it "defaults auth? to false" do
      expect(options.auth?).to be false
    end

    it "defaults pwa? to false" do
      expect(options.pwa?).to be false
    end

    it "defaults push? to false" do
      expect(options.push?).to be false
    end

    it "defaults active_resource? to false" do
      expect(options.active_resource?).to be false
    end

    it "defaults admin? to false" do
      expect(options.admin?).to be false
    end

    it "defaults ui? to false" do
      expect(options.ui?).to be false
    end

    it "defaults kamal? to false" do
      expect(options.kamal?).to be false
    end

    it "defaults docker? to false" do
      expect(options.docker?).to be false
    end

    it "defaults db_backup? to false" do
      expect(options.db_backup?).to be false
    end
  end

  describe "opt-out flags (default false)" do
    let(:options) { described_class.new }

    it "defaults skip_pagy? to false" do
      expect(options.skip_pagy?).to be false
    end
  end

  describe "predicate readers" do
    it "returns true when flag is set to true" do
      options = described_class.new(api: true)
      expect(options.api?).to be true
    end

    it "returns false when flag is set to false" do
      options = described_class.new(api: false)
      expect(options.api?).to be false
    end

    it "returns false when flag is not provided" do
      options = described_class.new
      expect(options.api?).to be false
    end
  end

  describe "#to_h" do
    it "returns a hash with metadata fields" do
      options = described_class.new(
        app_name: "myapp",
        ruby_version: "4.0.5",
        rails_version: "8.1.0"
      )

      hash = options.to_h
      expect(hash[:app_name]).to eq("myapp")
      expect(hash[:ruby_version]).to eq("4.0.5")
      expect(hash[:rails_version]).to eq("8.1.0")
    end

    it "returns a hash with flag values" do
      options = described_class.new(api: true, auth: false, skip_pagy: true)

      hash = options.to_h
      expect(hash[:api]).to be true
      expect(hash[:auth]).to be false
      expect(hash[:skip_pagy]).to be true
    end

    it "includes all opt-in flags" do
      options = described_class.new
      hash = options.to_h

      Develoz::Options::OPT_IN_FLAGS.each do |flag|
        expect(hash).to have_key(flag)
      end
    end

    it "includes all opt-out flags" do
      options = described_class.new
      hash = options.to_h

      Develoz::Options::OPT_OUT_FLAGS.each do |flag|
        expect(hash).to have_key(flag)
      end
    end

    it "includes metadata fields" do
      options = described_class.new
      hash = options.to_h

      expect(hash).to have_key(:app_name)
      expect(hash).to have_key(:ruby_version)
      expect(hash).to have_key(:rails_version)
    end
  end

  describe "metadata fields" do
    it "allows app_name to be nil" do
      options = described_class.new(app_name: nil)
      expect(options.app_name).to be_nil
    end

    it "allows ruby_version to be nil" do
      options = described_class.new(ruby_version: nil)
      expect(options.ruby_version).to be_nil
    end

    it "allows rails_version to be nil" do
      options = described_class.new(rails_version: nil)
      expect(options.rails_version).to be_nil
    end

    it "stores app_name as a string" do
      options = described_class.new(app_name: "demo")
      expect(options.app_name).to eq("demo")
    end
  end

  describe "combined flags" do
    it "allows multiple flags to be set simultaneously" do
      options = described_class.new(api: true, auth: true, pwa: true)
      expect(options.api?).to be true
      expect(options.auth?).to be true
      expect(options.pwa?).to be true
    end

    it "allows skip_pagy with other flags" do
      options = described_class.new(api: true, skip_pagy: true)
      expect(options.api?).to be true
      expect(options.skip_pagy?).to be true
    end

    it "allows some flags true and others false" do
      options = described_class.new(api: true, auth: false, pwa: true)
      expect(options.api?).to be true
      expect(options.auth?).to be false
      expect(options.pwa?).to be true
    end
  end
end
