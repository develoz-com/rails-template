# frozen_string_literal: true

require "spec_helper"
require "erb"

RSpec.describe "BinRunFidelity" do
  let(:fixture_path) { "spec/fixtures/canonical/develoz-com-agent/bin/run" }
  let(:template_path) { "lib/generators/develoz/docker/templates/bin_run.tt" }

  it "bin/run matches the canonical agent script" do
    rendered = ERB.new(File.read(template_path)).result(binding)

    expect(rendered).to match_canonical(fixture_path)
  end
end
