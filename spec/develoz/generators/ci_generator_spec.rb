# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/ci/ci_generator"

RSpec.describe Develoz::Generators::CiGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.add_ci_gems
    gen.create_ci_entrypoint
    gen.create_ci_config
    gen.create_rubocop_config
    gen.create_reek_config
    gen.create_biome_config
    gen.create_stylelint_config
    gen.create_haml_lint_config
    gen.create_markdownlint_config
    gen.create_yamllint_config
    gen.create_ci_workflow
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds rubocop-rails-omakase gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("rubocop-rails-omakase")
    end
  end

  it "adds reek gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("reek")
    end
  end

  it "adds flay gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("flay")
    end
  end

  it "adds brakeman gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("brakeman")
    end
  end

  it "adds bundler-audit gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("bundler-audit")
    end
  end

  it "adds haml_lint gem with require: false" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("haml_lint")
    end
  end

  it "generates bin/ci" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "bin/ci"))
    end
  end

  it "generates bin/ci with correct content" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      ci_entry = File.read(File.join(tmp, "bin/ci"))
      expect(ci_entry).to include("#!/usr/bin/env ruby")
      expect(ci_entry).to include('require "active_support/continuous_integration"')
      expect(ci_entry).to include("require_relative \"../config/ci.rb\"")
    end
  end

  it "generates config/ci.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/ci.rb"))
    end
  end

  it "generates config/ci.rb with CI.run and Setup step" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      ci_config = File.read(File.join(tmp, "config/ci.rb"))
      expect(ci_config).to include("CI.run do")
      expect(ci_config).to include("step \"Setup\"")
    end
  end

  it "generates config/ci.rb with Ruby style steps" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      ci_config = File.read(File.join(tmp, "config/ci.rb"))
      expect(ci_config).to include("step \"Style: Ruby\"")
      expect(ci_config).to include("step \"Style: Reek\"")
      expect(ci_config).to include("step \"Style: Flay\"")
    end
  end

  it "generates config/ci.rb with JS style steps" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      ci_config = File.read(File.join(tmp, "config/ci.rb"))
      expect(ci_config).to include("step \"Style: Biome\"")
      expect(ci_config).to include("step \"Style: Stylelint\"")
      expect(ci_config).to include("step \"Style: haml-lint\"")
    end
  end

  it "generates config/ci.rb with markdown and yaml steps" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      ci_config = File.read(File.join(tmp, "config/ci.rb"))
      expect(ci_config).to include("step \"Style: markdownlint\"")
      expect(ci_config).to include("step \"Style: yamllint\"")
    end
  end

  it "generates config/ci.rb with security steps" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      ci_config = File.read(File.join(tmp, "config/ci.rb"))
      expect(ci_config).to include("step \"Security: Gem audit\"")
      expect(ci_config).to include("step \"Security: Importmap audit\"")
      expect(ci_config).to include("step \"Security: Brakeman\"")
    end
  end

  it "generates config/ci.rb with RSpec test step" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      ci_config = File.read(File.join(tmp, "config/ci.rb"))
      expect(ci_config).to include("step \"Tests: RSpec\"")
      expect(ci_config).to include("Coverage gate")
    end
  end

  it "generates .rubocop.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".rubocop.yml"))
    end
  end

  it "generates .rubocop.yml with rubocop-rails-omakase inheritance" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rubocop = File.read(File.join(tmp, ".rubocop.yml"))
      expect(rubocop).to include("rubocop-rails-omakase")
      expect(rubocop).to include("TargetRubyVersion: 3.4")
    end
  end

  it "generates .reek.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".reek.yml"))
    end
  end

  it "generates .reek.yml with detector configuration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      reek = File.read(File.join(tmp, ".reek.yml"))
      expect(reek).to include("exclude_paths")
      expect(reek).to include("IrresponsibleModule")
    end
  end

  it "generates biome.json" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "biome.json"))
    end
  end

  it "generates biome.json with schema and formatter config" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      biome = File.read(File.join(tmp, "biome.json"))
      expect(biome).to include("biomejs.dev/schemas")
      expect(biome).to include("quoteStyle")
    end
  end

  it "generates .stylelintrc.json" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".stylelintrc.json"))
    end
  end

  it "generates .stylelintrc.json with stylelint config" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      stylelint = File.read(File.join(tmp, ".stylelintrc.json"))
      expect(stylelint).to include("stylelint-config-standard")
    end
  end

  it "generates .haml-lint.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".haml-lint.yml"))
    end
  end

  it "generates .haml-lint.yml with linter rules" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      haml_lint = File.read(File.join(tmp, ".haml-lint.yml"))
      expect(haml_lint).to include("LineLength")
      expect(haml_lint).to include("ViewLength")
    end
  end

  it "generates .markdownlint.json" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".markdownlint.json"))
    end
  end

  it "generates .markdownlint.json with rules config" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      md_lint = File.read(File.join(tmp, ".markdownlint.json"))
      expect(md_lint).to include("MD013")
      expect(md_lint).to include("line_length")
    end
  end

  it "generates .yamllint" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".yamllint"))
    end
  end

  it "generates .yamllint with rule definitions" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      yamllint = File.read(File.join(tmp, ".yamllint"))
      expect(yamllint).to include("extends: default")
      expect(yamllint).to include("truthy")
    end
  end

  it "generates .github/workflows/ci.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".github/workflows/ci.yml"))
    end
  end

  it "generates workflow with CI pipeline step" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      workflow = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(workflow).to include("actions/checkout@v4")
      expect(workflow).to include("ruby/setup-ruby@v1")
      expect(workflow).to include("bin/ci")
    end
  end

  it "is idempotent for gems" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("rubocop-rails-omakase").size).to eq(1)
      expect(gemfile.scan("reek").size).to eq(1)
      expect(gemfile.scan("flay").size).to eq(1)
    end
  end

  it "is idempotent for bin/ci" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "bin/ci"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "bin/ci"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for config/ci.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "config/ci.rb"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "config/ci.rb"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for linter configs" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_rubocop = File.read(File.join(tmp, ".rubocop.yml"))
      first_reek = File.read(File.join(tmp, ".reek.yml"))
      first_biome = File.read(File.join(tmp, "biome.json"))

      run_gen(tmp)

      expect(File.read(File.join(tmp, ".rubocop.yml"))).to eq(first_rubocop)
      expect(File.read(File.join(tmp, ".reek.yml"))).to eq(first_reek)
      expect(File.read(File.join(tmp, "biome.json"))).to eq(first_biome)
    end
  end

  it "is idempotent for workflow" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(first_content).to eq(second_content)
    end
  end

  it "generates entrypoint and config files" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "bin/ci"))
      expect(File).to exist(File.join(tmp, "config/ci.rb"))
    end
  end

  it "generates all linter config files" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".rubocop.yml"))
      expect(File).to exist(File.join(tmp, ".reek.yml"))
      expect(File).to exist(File.join(tmp, "biome.json"))
    end
  end

  it "generates all remaining linter configs" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".stylelintrc.json"))
      expect(File).to exist(File.join(tmp, ".haml-lint.yml"))
      expect(File).to exist(File.join(tmp, ".markdownlint.json"))
    end
  end

  it "generates yamllint and workflow files" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".yamllint"))
      expect(File).to exist(File.join(tmp, ".github/workflows/ci.yml"))
    end
  end

  it "bin/ci has executable shebang" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      ci_entry = File.read(File.join(tmp, "bin/ci"))
      expect(ci_entry.lines.first).to eq("#!/usr/bin/env ruby\n")
    end
  end

  it "config/ci.rb has coverage gate comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      ci_config = File.read(File.join(tmp, "config/ci.rb"))
      expect(ci_config).to include("100% line + branch")
    end
  end

  it ".rubocop.yml has LineLength config" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      rubocop = File.read(File.join(tmp, ".rubocop.yml"))
      expect(rubocop).to include("Layout/LineLength")
    end
  end

  it ".reek.yml has exclude_paths" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      reek = File.read(File.join(tmp, ".reek.yml"))
      expect(reek).to include("spec")
      expect(reek).to include("vendor")
    end
  end

  it "biome.json has formatter config" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      biome = File.read(File.join(tmp, "biome.json"))
      expect(biome).to include("indentWidth")
      expect(biome).to include("lineWidth")
    end
  end

  it ".github/workflows/ci.yml runs on push to main" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      workflow = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(workflow).to include("branches: [main]")
    end
  end

  it ".markdownlint.json has MD033 disabled" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      md_lint = File.read(File.join(tmp, ".markdownlint.json"))
      expect(md_lint).to include('"MD033": false')
    end
  end

  it ".stylelintrc.json has standard config" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      stylelint = File.read(File.join(tmp, ".stylelintrc.json"))
      expect(stylelint).to include("ignoreFiles")
    end
  end

  it ".haml-lint.yml has InstanceVariables disabled" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      haml_lint = File.read(File.join(tmp, ".haml-lint.yml"))
      expect(haml_lint).to include("InstanceVariables")
      expect(haml_lint).to include("enabled: false")
    end
  end

  it ".yamllint has line-length disabled" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      yamllint = File.read(File.join(tmp, ".yamllint"))
      expect(yamllint).to include("line-length: disable")
    end
  end

  it "brakeman gem is idempotent" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("brakeman").size).to eq(1)
    end
  end

  it "bundler-audit gem is idempotent" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("bundler-audit").size).to eq(1)
    end
  end

  it "haml_lint gem is idempotent" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("haml_lint").size).to eq(1)
    end
  end
end
