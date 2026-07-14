# frozen_string_literal: true

namespace :develoz do
  desc "Fetch canonical files from source repos"
  task fetch_canonical: :environment do
    $LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
    require "develoz"

    mapping = {
      "pull_request_template" => {
        repo: "develoz-com/inscripto-v2",
        path: ".github/pull_request_template.md",
        dest: "spec/fixtures/canonical/develoz-com-inscripto-v2/.github/pull_request_template.md"
      }
    }

    mapping.each do |name, config|
      puts "Fetching #{name}..."
      Develoz::CanonicalFetcher.fetch(
        repo: config[:repo],
        path: config[:path],
        dest: config[:dest]
      )
      puts "  -> #{config[:dest]}"
    end
  end
end
