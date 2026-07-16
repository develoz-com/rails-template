# frozen_string_literal: true

require "spec_helper"
require "erb"
require "tempfile"

RSpec.describe "ConstantsFidelity" do
  let(:fixture_path) { "spec/fixtures/canonical/LooperInsights-looper_core/config/constants.rb" }
  let(:template_path) { "lib/generators/develoz/tooling/templates/constants.rb.tt" }
  let(:app_name) { "sample_app" }
  let(:app_class) { "SampleApp" }

  def constant_names
    %w[DATABASE_HOST DATABASE_PORT DATABASE_NAME TEST_DATABASE_NAME REDIS_URL RAILS_MAX_THREADS SERVER_PORT HOST
       CACHING_DEV MEMCACHIER_SERVERS APP_NAME]
  end

  def canonical_projection
    canonical_lines = File.readlines(fixture_path)
    assignments = constant_names.map { |name| canonical_lines.find { |line| line.start_with?("#{name} =") } }

    [*canonical_lines.first(3), *assignments].join
  end

  def canonicalize(rendered)
    rendered.sub("module Constants\n", "")
            .sub("  # additional constants appended by generators\n", "")
            .delete_suffix("end\n")
            .gsub(/^  /, "")
            .sub('"sample_app"', '"core"')
            .sub('"SampleApp"', '"Webstores"')
  end

  it "preserves the canonical ENV-backed constants mechanism with illustrative values" do
    rendered = ERB.new(File.read(template_path)).result(binding)

    Tempfile.create("constants-projection") do |projection|
      projection.write(canonical_projection)
      projection.flush
      expect(canonicalize(rendered)).to match_canonical(projection.path)
    end
  end
end
