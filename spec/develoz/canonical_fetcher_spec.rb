# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"
require "tmpdir"

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/SubjectStub, RSpec/AnyInstance
RSpec.describe Develoz::CanonicalFetcher do
  subject(:fetcher) { described_class.new }

  let(:repo) { "owner/repo" }
  let(:path) { "path/to/file.txt" }
  let(:file_content) { "Hello, World!" }
  let(:encoded_content) { Base64.encode64(file_content).strip }
  let(:response_body) { { content: encoded_content }.to_json }
  let(:api_url) { "https://api.github.com/repos/#{repo}/contents/#{path}" }
  let(:dest) { File.join(Dir.mktmpdir, "file.txt") }

  after { WebMock.reset! }

  describe ".fetch" do
    it "delegates to instance fetch" do
      stub_request(:get, api_url)
        .to_return(status: 200, body: response_body)

      allow_any_instance_of(described_class).to receive(:fetch_token).and_return("test-token")

      described_class.fetch(repo: repo, path: path, dest: dest)

      expect(File.read(dest)).to eq(file_content)
    end
  end

  describe "#fetch" do
    context "with successful response" do
      it "downloads and decodes file content" do
        stub_request(:get, api_url)
          .to_return(status: 200, body: response_body)

        allow(fetcher).to receive(:fetch_token).and_return("test-token")

        fetcher.fetch(repo: repo, path: path, dest: dest)

        expect(File.read(dest)).to eq(file_content)
      end

      it "creates destination directory if missing" do
        nested_dest = File.join(Dir.mktmpdir, "subdir", "nested", "file.txt")

        stub_request(:get, api_url)
          .to_return(status: 200, body: response_body)

        allow(fetcher).to receive(:fetch_token).and_return("test-token")

        fetcher.fetch(repo: repo, path: path, dest: nested_dest)

        expect(File.exist?(nested_dest)).to be true
        expect(File.read(nested_dest)).to eq(file_content)
      end
    end

    context "with non-200 response" do
      it "raises error with clear message" do
        stub_request(:get, api_url)
          .to_return(status: 404, body: "Not Found")

        allow(fetcher).to receive(:fetch_token).and_return("test-token")

        expect do
          fetcher.fetch(repo: repo, path: path, dest: dest)
        end.to raise_error(%r{Failed to fetch #{repo}/#{path}: 404})
      end

      it "raises error on 500" do
        stub_request(:get, api_url)
          .to_return(status: 500, body: "Server Error")

        allow(fetcher).to receive(:fetch_token).and_return("test-token")

        expect do
          fetcher.fetch(repo: repo, path: path, dest: dest)
        end.to raise_error(%r{Failed to fetch #{repo}/#{path}: 500})
      end
    end

    context "with missing token" do
      it "makes request without Authorization header when token is nil" do
        stub_request(:get, api_url)
          .with { |request| request.headers["Authorization"].nil? }
          .to_return(status: 200, body: response_body)

        allow(fetcher).to receive(:fetch_token).and_return(nil)

        fetcher.fetch(repo: repo, path: path, dest: dest)

        expect(File.read(dest)).to eq(file_content)
      end
    end

    context "with token from environment" do
      it "uses token in Authorization header" do
        stub_request(:get, api_url)
          .with(headers: { "Authorization" => "token test-token" })
          .to_return(status: 200, body: response_body)

        allow(fetcher).to receive(:fetch_token).and_return("test-token")

        fetcher.fetch(repo: repo, path: path, dest: dest)

        expect(File.read(dest)).to eq(file_content)
      end
    end

    context "with multiline content" do
      let(:file_content) { "Line 1\nLine 2\nLine 3\n" }

      it "preserves newlines" do
        stub_request(:get, api_url)
          .to_return(status: 200, body: response_body)

        allow(fetcher).to receive(:fetch_token).and_return("test-token")

        fetcher.fetch(repo: repo, path: path, dest: dest)

        expect(File.read(dest)).to eq(file_content)
      end
    end
  end

  describe "#fetch_token" do
    it "returns ENV['GH_TOKEN'] when set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GH_TOKEN").and_return("env-token")

      token = fetcher.send(:fetch_token)

      expect(token).to eq("env-token")
    end

    it "falls back to shell token when ENV var not set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GH_TOKEN").and_return(nil)

      token = fetcher.send(:fetch_token)

      expect(token).not_to be_nil
    end

    it "returns nil when both sources fail" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GH_TOKEN").and_return(nil)

      allow_any_instance_of(described_class).to receive(:shell_token).and_return(nil)

      token = fetcher.send(:fetch_token)

      expect(token).to be_nil
    end
  end

  describe "#shell_token rescue" do
    it "returns nil when shell command raises error" do
      new_fetcher = described_class.new
      allow(new_fetcher).to receive(:`).and_raise(StandardError, "command failed")

      token = new_fetcher.send(:shell_token)

      expect(token).to be_nil
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/SubjectStub, RSpec/AnyInstance
