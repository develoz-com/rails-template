# frozen_string_literal: true

require "spec_helper"
require "erb"

RSpec.describe "DocSpecsFidelity" do
  let(:fixture_base) { "spec/fixtures/canonical/LooperInsights-looper_core" }
  let(:template_base) { "lib/generators/develoz/doc_specs/templates" }

  def render_template(template_path)
    template_content = File.read(template_path)
    ERB.new(template_content).result(binding)
  end

  it "bin/generate-docs matches canonical fixture" do
    rendered = render_template("#{template_base}/bin/generate-docs.tt")

    expect(rendered).to match_canonical("#{fixture_base}/bin/generate-docs")
  end
end
