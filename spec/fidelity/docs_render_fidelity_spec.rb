# frozen_string_literal: true

require "spec_helper"
require "erb"

RSpec.describe "DocsRenderFidelity" do
  let(:fixture_base) { "spec/fixtures/canonical/LooperInsights-looper_core" }
  let(:template_base) { "lib/generators/develoz/docs_render/templates" }

  def render_template(template_path)
    template_content = File.read(template_path)
    ERB.new(template_content).result(binding)
  end

  it "document.rb matches canonical fixture" do
    rendered = render_template("#{template_base}/app/models/document.rb.tt")

    expect(rendered).to match_canonical("#{fixture_base}/app/models/document.rb")
  end

  it "docs.js matches canonical fixture" do
    rendered = render_template("#{template_base}/app/javascript/docs.js.tt")

    expect(rendered).to match_canonical("#{fixture_base}/app/javascript/docs.js")
  end

  it "documentation.scss matches canonical fixture" do
    rendered = render_template("#{template_base}/app/assets/stylesheets/documentation.scss.tt")

    expect(rendered).to match_canonical("#{fixture_base}/app/assets/stylesheets/documentation.scss")
  end
end
