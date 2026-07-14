# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"
require "tmpdir"

RSpec.describe Develoz::VersionResolver do
  describe ".resolve" do
    it "delegates to instance method" do
      resolver = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:resolve).with(ruby: nil, rails: nil).and_return({ ruby: "4.0.5", rails: "8.1" })

      result = described_class.resolve(ruby: nil, rails: nil)

      expect(result).to eq({ ruby: "4.0.5", rails: "8.1" })
    end
  end

  describe "#resolve" do
    subject(:resolver) { described_class.new }

    context "when both ruby and rails are provided" do
      it "returns the provided versions without network calls" do
        result = resolver.resolve(ruby: "3.3.0", rails: "7.1.0")

        expect(result).to eq({ ruby: "3.3.0", rails: "7.1.0" })
      end
    end

    context "when ruby is provided but rails is not" do
      it "returns provided ruby and fetches rails" do
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 200, body: '{"version":"8.0.0"}')

        result = resolver.resolve(ruby: "3.3.0", rails: nil)

        expect(result).to eq({ ruby: "3.3.0", rails: "8.0.0" })
      end
    end

    context "when rails is provided but ruby is not" do
      it "returns provided rails and fetches ruby" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 200, body: "3.4.0\n")

        result = resolver.resolve(ruby: nil, rails: "7.1.0")

        expect(result).to eq({ ruby: "3.4.0", rails: "7.1.0" })
      end
    end

    context "when neither ruby nor rails are provided" do
      it "fetches both versions from network" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 200, body: "3.4.0\n")
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 200, body: '{"version":"8.0.0"}')

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "3.4.0", rails: "8.0.0" })
      end
    end

    context "when ruby fetch times out" do
      it "returns ruby fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_timeout
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 200, body: '{"version":"8.0.0"}')

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "4.0.5", rails: "8.0.0" })
      end
    end

    context "when rails fetch times out" do
      it "returns rails fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 200, body: "3.4.0\n")
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_timeout

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "3.4.0", rails: "8.1" })
      end
    end

    context "when ruby fetch returns 500" do
      it "returns ruby fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 500, body: "Internal Server Error")
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 200, body: '{"version":"8.0.0"}')

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "4.0.5", rails: "8.0.0" })
      end
    end

    context "when rails fetch returns 500" do
      it "returns rails fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 200, body: "3.4.0\n")
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 500, body: "Internal Server Error")

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "3.4.0", rails: "8.1" })
      end
    end

    context "when ruby fetch returns empty body" do
      it "returns ruby fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 200, body: "")
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 200, body: '{"version":"8.0.0"}')

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "4.0.5", rails: "8.0.0" })
      end
    end

    context "when rails fetch returns empty version" do
      it "returns rails fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 200, body: "3.4.0\n")
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 200, body: '{"version":""}')

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "3.4.0", rails: "8.1" })
      end
    end

    context "when rails fetch returns missing version key" do
      it "returns rails fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 200, body: "3.4.0\n")
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 200, body: '{"other":"value"}')

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "3.4.0", rails: "8.1" })
      end
    end

    context "when rails fetch returns invalid JSON" do
      it "returns rails fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 200, body: "3.4.0\n")
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 200, body: "not json")

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "3.4.0", rails: "8.1" })
      end
    end

    context "when ruby fetch raises connection error" do
      it "returns ruby fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_raise(Errno::ECONNREFUSED)
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_return(status: 200, body: '{"version":"8.0.0"}')

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "4.0.5", rails: "8.0.0" })
      end
    end

    context "when rails fetch raises connection error" do
      it "returns rails fallback" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_return(status: 200, body: "3.4.0\n")
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_raise(Errno::ECONNREFUSED)

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "3.4.0", rails: "8.1" })
      end
    end

    context "when both fetches fail" do
      it "returns both fallbacks" do
        stub_request(:get, Develoz::VersionResolver::RUBY_VERSION_URL)
          .to_timeout
        stub_request(:get, Develoz::VersionResolver::RAILS_VERSION_URL)
          .to_timeout

        result = resolver.resolve(ruby: nil, rails: nil)

        expect(result).to eq({ ruby: "4.0.5", rails: "8.1" })
      end
    end
  end

  describe ".write_tool_versions" do
    it "delegates to instance method" do
      resolver = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:write_tool_versions).with("/tmp", ruby: "3.4.0", node: "24.15.0")

      described_class.write_tool_versions("/tmp", ruby: "3.4.0", node: "24.15.0")

      expect(resolver).to have_received(:write_tool_versions).with("/tmp", ruby: "3.4.0", node: "24.15.0")
    end
  end

  describe "#write_tool_versions" do
    subject(:resolver) { described_class.new }

    it "writes .tool-versions file with ruby and node versions" do
      Dir.mktmpdir do |tmpdir|
        resolver.write_tool_versions(tmpdir, ruby: "3.4.0", node: "24.15.0")

        path = File.join(tmpdir, ".tool-versions")
        expect(File.exist?(path)).to be true
        expect(File.read(path)).to eq("ruby 3.4.0\nnodejs 24.15.0\n")
      end
    end

    it "uses default node version when not provided" do
      Dir.mktmpdir do |tmpdir|
        resolver.write_tool_versions(tmpdir, ruby: "3.4.0")

        path = File.join(tmpdir, ".tool-versions")
        expect(File.read(path)).to eq("ruby 3.4.0\nnodejs 24.15.0\n")
      end
    end

    it "overwrites existing .tool-versions file" do
      Dir.mktmpdir do |tmpdir|
        path = File.join(tmpdir, ".tool-versions")
        File.write(path, "ruby 3.3.0\nnodejs 20.0.0\n")

        resolver.write_tool_versions(tmpdir, ruby: "3.4.0", node: "24.15.0")

        expect(File.read(path)).to eq("ruby 3.4.0\nnodejs 24.15.0\n")
      end
    end
  end

  describe ".write_ruby_version" do
    it "delegates to instance method" do
      resolver = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:write_ruby_version).with("/tmp", ruby: "3.4.0")

      described_class.write_ruby_version("/tmp", ruby: "3.4.0")

      expect(resolver).to have_received(:write_ruby_version).with("/tmp", ruby: "3.4.0")
    end
  end

  describe "#write_ruby_version" do
    subject(:resolver) { described_class.new }

    it "writes .ruby-version file with ruby version" do
      Dir.mktmpdir do |tmpdir|
        resolver.write_ruby_version(tmpdir, ruby: "3.4.0")

        path = File.join(tmpdir, ".ruby-version")
        expect(File.exist?(path)).to be true
        expect(File.read(path)).to eq("3.4.0\n")
      end
    end

    it "overwrites existing .ruby-version file" do
      Dir.mktmpdir do |tmpdir|
        path = File.join(tmpdir, ".ruby-version")
        File.write(path, "3.3.0\n")

        resolver.write_ruby_version(tmpdir, ruby: "3.4.0")

        expect(File.read(path)).to eq("3.4.0\n")
      end
    end
  end
end
