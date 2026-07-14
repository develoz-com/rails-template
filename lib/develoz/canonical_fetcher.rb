# frozen_string_literal: true

require "net/http"
require "base64"
require "json"
require "fileutils"

module Develoz
  class CanonicalFetcher
    GITHUB_API_BASE = "https://api.github.com"

    def self.fetch(repo:, path:, dest:)
      new.fetch(repo: repo, path: path, dest: dest)
    end

    def fetch(repo:, path:, dest:)
      url = "#{GITHUB_API_BASE}/repos/#{repo}/contents/#{path}"
      token = fetch_token

      response = make_request(url, token)
      raise "Failed to fetch #{repo}/#{path}: #{response.code}" unless response.code == "200"

      content = JSON.parse(response.body)["content"]
      decoded = Base64.decode64(content)

      FileUtils.mkdir_p(File.dirname(dest))
      File.write(dest, decoded)
    end

    private

    def fetch_token
      ENV["GH_TOKEN"] || shell_token
    end

    def shell_token
      `gh auth token 2>/dev/null`.strip
    rescue StandardError
      nil
    end

    def make_request(url, token)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Get.new(uri.request_uri)
      request["Authorization"] = "token #{token}" if token

      http.request(request)
    end
  end
end
