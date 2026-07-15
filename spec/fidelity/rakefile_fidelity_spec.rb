# frozen_string_literal: true

require "spec_helper"
require "erb"

RSpec.describe "RakefileFidelity" do
  let(:fixture_path) { "spec/fixtures/canonical/LooperInsights-looper_core/Rakefile" }
  let(:template_path) { "lib/generators/develoz/ci/templates/Rakefile.tt" }

  it "Rakefile lint tasks match the canonical looper_core file" do
    rendered = ERB.new(File.read(template_path)).result(binding)

    expect(rendered).to match_canonical(fixture_path)
  end
end
