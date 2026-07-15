# frozen_string_literal: true

require "net/http"
require "json"

module Develoz
  class VersionResolver
    RUBY_FALLBACK = "4.0.5"
    RAILS_FALLBACK = "8.1"

    RUBY_VERSION_URL = "https://cache.ruby-lang.org/pub/misc/latest_ruby"
    RAILS_VERSION_URL = "https://rubygems.org/api/v1/versions/rails/latest.json"

    TIMEOUT_SECONDS = 5

    def self.resolve(ruby: nil, rails: nil)
      new.resolve(ruby:, rails:)
    end

    def resolve(ruby: nil, rails: nil)
      {
        ruby: ruby || fetch_ruby_version,
        rails: rails || fetch_rails_version
      }
    end

    def self.write_tool_versions(dir, ruby:, node: "24.15.0")
      new.write_tool_versions(dir, ruby:, node:)
    end

    def write_tool_versions(dir, ruby:, node: "24.15.0")
      path = File.join(dir, ".tool-versions")
      content = "ruby #{ruby}\nnodejs #{node}\n"
      File.write(path, content)
    end

    def self.write_ruby_version(dir, ruby:)
      new.write_ruby_version(dir, ruby:)
    end

    def write_ruby_version(dir, ruby:)
      path = File.join(dir, ".ruby-version")
      content = "#{ruby}\n"
      File.write(path, content)
    end

    private

    def fetch_ruby_version
      response = fetch_url(RUBY_VERSION_URL)
      return RUBY_FALLBACK unless response

      version = response.strip
      version.empty? ? RUBY_FALLBACK : version
    end

    def fetch_rails_version
      response = fetch_url(RAILS_VERSION_URL)
      return RAILS_FALLBACK unless response

      data = JSON.parse(response)
      version = data["version"]
      version.presence || RAILS_FALLBACK
    rescue JSON::ParserError
      RAILS_FALLBACK
    end

    def fetch_url(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = TIMEOUT_SECONDS
      http.read_timeout = TIMEOUT_SECONDS

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      return response.body if response.is_a?(Net::HTTPSuccess)

      nil
    rescue StandardError
      nil
    end
  end
end
