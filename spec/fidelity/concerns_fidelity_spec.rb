# frozen_string_literal: true

require "spec_helper"
require "erb"

RSpec.describe "ConcernsFidelity" do
  let(:fixture_base) { "spec/fixtures/canonical/LooperInsights-looper_core/app/models/concerns" }
  let(:template_base) { "lib/generators/develoz/concerns/templates/app/models/concerns" }

  def render_template(template_path)
    template_content = File.read(template_path)
    ERB.new(template_content).result(binding)
  end

  it "searchable_concern.rb matches canonical fixture" do
    rendered = render_template("#{template_base}/searchable_concern.rb.tt")

    expect(rendered).to match_canonical("#{fixture_base}/searchable_concern.rb")
  end

  it "optimized_finders.rb matches canonical fixture" do
    rendered = render_template("#{template_base}/optimized_finders.rb.tt")

    expect(rendered).to match_canonical("#{fixture_base}/optimized_finders.rb")
  end

  it "transitionable.rb matches canonical fixture" do
    rendered = render_template("#{template_base}/transitionable.rb.tt")

    expect(rendered).to match_canonical("#{fixture_base}/transitionable.rb")
  end

  it "configurable.rb matches canonical fixture" do
    rendered = render_template("#{template_base}/configurable.rb.tt")

    expect(rendered).to match_canonical("#{fixture_base}/configurable.rb")
  end

  it "configuration.rb matches canonical fixture" do
    template_path = "lib/generators/develoz/concerns/templates/app/models/configuration.rb.tt"
    fixture_path = "spec/fixtures/canonical/LooperInsights-looper_core/app/models/configuration.rb"
    rendered = render_template(template_path)

    expect(rendered).to match_canonical(fixture_path)
  end
end
