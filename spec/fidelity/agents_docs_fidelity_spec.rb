# frozen_string_literal: true

require "spec_helper"
require "erb"

RSpec.describe "AgentsDocsFidelity" do
  let(:fixture_path) { "spec/fixtures/canonical/develoz-com-inscripto-v2/.github/pull_request_template.md" }
  let(:template_path) { "lib/generators/develoz/agents_docs/templates/.github/pull_request_template.md.tt" }

  it "renders PR template to match canonical fixture" do
    template_content = File.read(template_path)
    rendered = ERB.new(template_content).result(binding)

    expect(rendered).to match_canonical(fixture_path)
  end
end
