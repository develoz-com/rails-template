# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/solid/solid_generator"

RSpec.describe Develoz::Generators::SolidGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      # seed a minimal app so add_gem and insert_route have targets
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.add_solid_gems
    gen.create_queue_config
    gen.create_cache_config
    gen.create_cable_config
    gen.create_recurring_config
    gen.create_application_job
    gen.create_mission_control_initializer
    gen.create_solid_initializer
    gen.insert_mission_control_route
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds solid_queue gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("solid_queue")
    end
  end

  it "adds solid_cache gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("solid_cache")
    end
  end

  it "adds solid_cable gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("solid_cable")
    end
  end

  it "adds mission_control-jobs gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("mission_control-jobs")
    end
  end

  it "generates config/queue.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/queue.yml"))
    end
  end

  it "generates queue.yml with correct structure" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      queue_yml = File.read(File.join(tmp, "config/queue.yml"))
      expect(queue_yml).to include("default: &default", "dispatchers:", "workers:")
      expect(queue_yml).to include("development:", "test:", "production:")
    end
  end

  it "generates config/cache.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/cache.yml"))
    end
  end

  it "generates cache.yml with correct structure" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      cache_yml = File.read(File.join(tmp, "config/cache.yml"))
      expect(cache_yml).to include("default: &default", "store_options:", "max_size:")
      expect(cache_yml).to include("namespace:", "production:", "database: cache")
    end
  end

  it "generates config/cable.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/cable.yml"))
    end
  end

  it "generates cable.yml with correct structure" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      cable_yml = File.read(File.join(tmp, "config/cable.yml"))
      expect(cable_yml).to include("development:", "adapter: async")
      expect(cable_yml).to include("test:", "adapter: test")
      expect(cable_yml).to include("production:", "adapter: redis")
    end
  end

  it "generates config/recurring.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/recurring.yml"))
    end
  end

  it "generates recurring.yml with correct structure" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      recurring_yml = File.read(File.join(tmp, "config/recurring.yml"))
      expect(recurring_yml).to include("development:")
      expect(recurring_yml).to include("clear_solid_queue_finished_jobs:")
      expect(recurring_yml).to include("production:")
    end
  end

  it "generates app/jobs/application_job.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/jobs/application_job.rb"))
    end
  end

  it "generates application_job with correct structure" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      app_job = File.read(File.join(tmp, "app/jobs/application_job.rb"))
      expect(app_job).to include("class ApplicationJob < ActiveJob::Base")
      expect(app_job).to include("# Automatically retry jobs that encountered a deadlock")
      expect(app_job).to include("# Most jobs are safe to ignore")
    end
  end

  it "generates config/initializers/mission_control.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/mission_control.rb"))
    end
  end

  it "generates mission_control initializer with correct structure" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      mc_init = File.read(File.join(tmp, "config/initializers/mission_control.rb"))
      expect(mc_init).to include("MissionControl::Jobs.http_basic_auth_user")
      expect(mc_init).to include("MissionControl::Jobs.http_basic_auth_password")
      expect(mc_init).to include("ENV.fetch")
    end
  end

  it "generates config/initializers/solid.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/solid.rb"))
    end
  end

  it "generates solid initializer with correct structure" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      solid_init = File.read(File.join(tmp, "config/initializers/solid.rb"))
      expect(solid_init).to include("config.active_job.queue_adapter = :solid_queue")
      expect(solid_init).to include("config.cache_store = :solid_cache_store")
    end
  end

  it "inserts mission_control route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include('mount MissionControl::Jobs::Engine, at: "/jobs"')
    end
  end

  it "is idempotent for gems" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("solid_queue").size).to eq(1)
      expect(gemfile.scan("solid_cache").size).to eq(1)
      expect(gemfile.scan("solid_cable").size + gemfile.scan("mission_control-jobs").size).to eq(2)
    end
  end

  it "is idempotent for queue.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "config/queue.yml"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "config/queue.yml"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for cache.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "config/cache.yml"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "config/cache.yml"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for cable.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "config/cable.yml"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "config/cable.yml"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for recurring.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "config/recurring.yml"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "config/recurring.yml"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for application_job.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "app/jobs/application_job.rb"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "app/jobs/application_job.rb"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for mission_control initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "config/initializers/mission_control.rb"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "config/initializers/mission_control.rb"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for solid initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "config/initializers/solid.rb"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "config/initializers/solid.rb"))
      expect(first_content).to eq(second_content)
    end
  end

  it "is idempotent for routes" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first_content = File.read(File.join(tmp, "config/routes.rb"))
      run_gen(tmp)
      second_content = File.read(File.join(tmp, "config/routes.rb"))
      expect(first_content).to eq(second_content)
    end
  end

  it "generates all initializers" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/mission_control.rb"))
      expect(File).to exist(File.join(tmp, "config/initializers/solid.rb"))
    end
  end

  it "mission_control initializer has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      mc_init = File.read(File.join(tmp, "config/initializers/mission_control.rb"))
      expect(mc_init).to start_with("# frozen_string_literal: true")
    end
  end

  it "solid initializer has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      solid_init = File.read(File.join(tmp, "config/initializers/solid.rb"))
      expect(solid_init).to start_with("# frozen_string_literal: true")
    end
  end

  it "queue.yml includes processes configuration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      queue_yml = File.read(File.join(tmp, "config/queue.yml"))
      expect(queue_yml).to include("processes:")
    end
  end

  it "cable.yml includes redis adapter for production" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      cable_yml = File.read(File.join(tmp, "config/cable.yml"))
      expect(cable_yml).to include("adapter: redis")
    end
  end

  it "cache.yml includes max_size configuration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      cache_yml = File.read(File.join(tmp, "config/cache.yml"))
      expect(cache_yml).to include("max_size:")
    end
  end

  it "recurring.yml includes clear_solid_queue_finished_jobs task" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      recurring_yml = File.read(File.join(tmp, "config/recurring.yml"))
      expect(recurring_yml).to include("clear_solid_queue_finished_jobs")
      expect(recurring_yml).to include("SolidQueue::Job.clear_finished_in_batches")
    end
  end
end
