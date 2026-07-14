# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/admin/admin_generator"

RSpec.describe Develoz::Generators::AdminGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
      yield dir
    end
  end

  def run_gen(tmp_dir, opts = {})
    gen = described_class.new([], opts, destination_root: tmp_dir)
    gen.create_admin_base_controller
    gen.create_admin_layout
    gen.create_dashboard_controller
    gen.create_dashboard_view
    gen.insert_admin_routes
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "generates admin base controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/controllers/admin/base_controller.rb"))
    end
  end

  it "base controller has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/admin/base_controller.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "base controller inherits from ApplicationController" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/admin/base_controller.rb"))
      expect(content).to include("class BaseController < ApplicationController")
    end
  end

  it "base controller sets admin layout" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/admin/base_controller.rb"))
      expect(content).to include('layout "admin"')
    end
  end

  it "generates admin layout" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/layouts/admin.html.erb"))
    end
  end

  it "admin layout has nav element" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/layouts/admin.html.erb"))
      expect(content).to include("<nav")
    end
  end

  it "admin layout has main element" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/layouts/admin.html.erb"))
      expect(content).to include("<main")
    end
  end

  it "admin layout has dashboard link" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/layouts/admin.html.erb"))
      expect(content).to include("admin_root_path")
    end
  end

  it "admin layout renders yield" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/layouts/admin.html.erb"))
      expect(content).to include("<%= yield %>")
    end
  end

  it "admin layout does not hard-require develoz-ui" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/layouts/admin.html.erb"))
      expect(content).not_to include("develoz_ui")
      expect(content).not_to include("develoz-ui")
    end
  end

  it "generates dashboard controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/controllers/admin/dashboard_controller.rb"))
    end
  end

  it "dashboard controller has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/admin/dashboard_controller.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "dashboard controller inherits from Admin::BaseController" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/admin/dashboard_controller.rb"))
      expect(content).to include("class DashboardController < Admin::BaseController")
    end
  end

  it "dashboard controller has index action" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/admin/dashboard_controller.rb"))
      expect(content).to include("def index")
    end
  end

  it "generates dashboard index view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/admin/dashboard/index.html.erb"))
    end
  end

  it "dashboard view has heading" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/admin/dashboard/index.html.erb"))
      expect(content).to include("Dashboard")
    end
  end

  it "inserts admin namespace route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include("namespace :admin")
    end
  end

  it "inserts dashboard root route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include('root "dashboard#index"')
    end
  end

  it "is idempotent for admin base controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/controllers/admin/base_controller.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/controllers/admin/base_controller.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for admin layout" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/layouts/admin.html.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/layouts/admin.html.erb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for dashboard controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/controllers/admin/dashboard_controller.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/controllers/admin/dashboard_controller.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for dashboard view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/admin/dashboard/index.html.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/admin/dashboard/index.html.erb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for routes" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes.scan("namespace :admin").length).to eq(1)
    end
  end

  it "ui_enabled? returns false by default" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      expect(gen.ui_enabled?).to be(false)
    end
  end

  it "ui_enabled? returns true when ui option is set" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], { "ui" => true }, destination_root: tmp)
      expect(gen.ui_enabled?).to be(true)
    end
  end

  it "degrades gracefully without --ui flag" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      layout = File.read(File.join(tmp, "app/views/layouts/admin.html.erb"))
      expect(layout).to include("<style>")
      expect(layout).not_to include("develoz-ui")
    end
  end
end
