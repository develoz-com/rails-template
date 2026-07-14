# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/doc_specs/doc_specs_generator"

RSpec.describe Develoz::Generators::DocSpecsGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.create_generate_docs_script
    gen.create_doc_screenshot_helper
    gen.create_docs_check_rake_task
    gen.create_example_system_spec
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "generates bin/generate-docs" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "bin/generate-docs"))
    end
  end

  it "makes bin/generate-docs executable" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      stat = File.stat(File.join(tmp, "bin/generate-docs"))
      expect(stat.mode & 0o111).to be_nonzero
    end
  end

  it "bin/generate-docs has ruby shebang" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/generate-docs"))
      expect(content).to start_with("#!/usr/bin/env ruby")
    end
  end

  it "bin/generate-docs has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/generate-docs"))
      expect(content).to include("# frozen_string_literal: true")
    end
  end

  it "generates doc_screenshot_helper.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/support/doc_screenshot_helper.rb"))
    end
  end

  it "doc_screenshot_helper defines doc_screenshot method" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/support/doc_screenshot_helper.rb"))
      expect(content).to include("def doc_screenshot")
    end
  end

  it "doc_screenshot_helper has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/support/doc_screenshot_helper.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "doc_screenshot_helper includes RSpec configure" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/support/doc_screenshot_helper.rb"))
      expect(content).to include("RSpec.configure")
    end
  end

  it "generates docs_check.rake" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "lib/tasks/docs_check.rake"))
    end
  end

  it "docs_check.rake defines docs:check task" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "lib/tasks/docs_check.rake"))
      expect(content).to include("namespace :docs")
      expect(content).to include("task :check")
    end
  end

  it "docs_check.rake has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "lib/tasks/docs_check.rake"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates example_doc_spec.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/system/example_doc_spec.rb"))
    end
  end

  it "example spec has @category directive" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/system/example_doc_spec.rb"))
      expect(content).to include("@category")
    end
  end

  it "example spec has @order directive" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/system/example_doc_spec.rb"))
      expect(content).to include("@order")
    end
  end

  it "example spec has doc_screenshot call" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/system/example_doc_spec.rb"))
      expect(content).to include("doc_screenshot(")
    end
  end

  it "example spec has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/system/example_doc_spec.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "is idempotent for bin/generate-docs" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "bin/generate-docs"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "bin/generate-docs"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for doc_screenshot_helper" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/support/doc_screenshot_helper.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/support/doc_screenshot_helper.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for docs_check.rake" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "lib/tasks/docs_check.rake"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "lib/tasks/docs_check.rake"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for example_doc_spec" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/system/example_doc_spec.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/system/example_doc_spec.rb"))
      expect(first).to eq(second)
    end
  end

  it "preserves executable bit on idempotent re-run" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      stat = File.stat(File.join(tmp, "bin/generate-docs"))
      expect(stat.mode & 0o111).to be_nonzero
    end
  end
end
