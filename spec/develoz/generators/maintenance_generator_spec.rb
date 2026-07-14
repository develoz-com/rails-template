# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/maintenance/maintenance_generator"

RSpec.describe Develoz::Generators::MaintenanceGenerator do
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
    gen.add_maintenance_tasks_gem
    gen.insert_maintenance_tasks_route
    gen.create_example_task
    gen.create_rake_task
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds maintenance_tasks gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("maintenance_tasks")
    end
  end

  it "inserts maintenance_tasks route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include('mount MaintenanceTasks::Engine, at: "/maintenance_tasks"')
    end
  end

  it "generates app/tasks/maintenance/example_task.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/tasks/maintenance/example_task.rb"))
    end
  end

  it "generates example_task with correct structure" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/tasks/maintenance/example_task.rb"))
      expect(content).to include("class ExampleTask < MaintenanceTasks::Task")
      expect(content).to include("def collection")
      expect(content).to include("def process")
    end
  end

  it "example_task has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/tasks/maintenance/example_task.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates lib/tasks/maintenance_counters.rake" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "lib/tasks/maintenance_counters.rake"))
    end
  end

  it "rake task has counters namespace" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "lib/tasks/maintenance_counters.rake"))
      expect(content).to include("namespace :maintenance do")
      expect(content).to include("task update_counters:")
      expect(content).to include("task purge_stale:")
    end
  end

  it "rake task has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "lib/tasks/maintenance_counters.rake"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "is idempotent for gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("maintenance_tasks").size).to eq(1)
    end
  end

  it "is idempotent for route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes.scan("MaintenanceTasks::Engine").size).to eq(1)
    end
  end

  it "is idempotent for example_task" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/tasks/maintenance/example_task.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/tasks/maintenance/example_task.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for rake task" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "lib/tasks/maintenance_counters.rake"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "lib/tasks/maintenance_counters.rake"))
      expect(first).to eq(second)
    end
  end
end
