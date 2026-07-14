# frozen_string_literal: true

require "spec_helper"
require "erb"

RSpec.describe "VersioningFidelity" do
  let(:fixture_base) { "spec/fixtures/canonical/develoz-com-inscripto-v2" }
  let(:template_base) { "lib/generators/develoz/versioning/templates" }

  def render_template(template_path)
    template_content = File.read(template_path)
    ERB.new(template_content).result(binding)
  end

  it "app_version method matches canonical inscripto-v2 fixture" do
    rendered = render_template("#{template_base}/app/helpers/application_helper.rb.tt")
    fixture = File.read("#{fixture_base}/app/helpers/app_version.rb")

    expect(rendered).to include(fixture)
  end
end
