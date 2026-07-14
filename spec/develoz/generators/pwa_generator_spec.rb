# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/pwa/pwa_generator"

RSpec.describe Develoz::Generators::PwaGenerator do
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
    gen.create_pwa_controller
    gen.create_manifest_view
    gen.create_service_worker_view
    gen.create_offline_page
    gen.create_registration_js
    gen.insert_pwa_routes
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "generates pwa controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/controllers/pwa_controller.rb"))
    end
  end

  it "pwa controller has manifest action" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/pwa_controller.rb"))
      expect(content).to include("def manifest")
    end
  end

  it "pwa controller has service_worker action" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/pwa_controller.rb"))
      expect(content).to include("def service_worker")
    end
  end

  it "pwa controller has offline action" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/pwa_controller.rb"))
      expect(content).to include("def offline")
    end
  end

  it "pwa controller skips forgery protection" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/pwa_controller.rb"))
      expect(content).to include("skip_forgery_protection")
    end
  end

  it "pwa controller has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/pwa_controller.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates manifest view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/pwa/manifest.json.erb"))
    end
  end

  it "manifest has name field" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/manifest.json.erb"))
      expect(content).to include('"name"')
    end
  end

  it "manifest has icons" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/manifest.json.erb"))
      expect(content).to include("icons")
    end
  end

  it "manifest has theme_color" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/manifest.json.erb"))
      expect(content).to include("theme_color")
    end
  end

  it "manifest has display standalone" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/manifest.json.erb"))
      expect(content).to include('"standalone"')
    end
  end

  it "manifest has start_url" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/manifest.json.erb"))
      expect(content).to include("start_url")
    end
  end

  it "generates service worker view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
    end
  end

  it "service worker has install listener" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(content).to include('addEventListener("install"')
    end
  end

  it "service worker has activate listener" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(content).to include('addEventListener("activate"')
    end
  end

  it "service worker has fetch listener" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(content).to include('addEventListener("fetch"')
    end
  end

  it "service worker caches app shell on install" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(content).to include("APP_SHELL")
      expect(content).to include("cache.addAll")
    end
  end

  it "service worker cleans old caches on activate" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(content).to include("caches.delete")
    end
  end

  it "service worker uses cache-first for static assets" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(content).to include("cacheFirst")
    end
  end

  it "service worker uses network-first for pages" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(content).to include("networkFirst")
    end
  end

  it "service worker has offline fallback" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(content).to include("/offline")
    end
  end

  it "service worker does not include push handler" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(content).not_to include('addEventListener("push"')
    end
  end

  it "generates offline page" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/pwa/offline.html.erb"))
    end
  end

  it "offline page has offline message" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/offline.html.erb"))
      expect(content).to include("offline")
    end
  end

  it "offline page has retry button" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/offline.html.erb"))
      expect(content).to include("Retry")
    end
  end

  it "generates registration js" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/javascript/pwa/registration.js"))
    end
  end

  it "registration js registers service worker" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/javascript/pwa/registration.js"))
      expect(content).to include("register")
    end
  end

  it "registration js handles update found" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/javascript/pwa/registration.js"))
      expect(content).to include("updatefound")
    end
  end

  it "inserts manifest route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include("pwa#manifest")
    end
  end

  it "inserts service-worker route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include("pwa#service_worker")
    end
  end

  it "inserts offline route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include("pwa#offline")
    end
  end

  it "is idempotent for pwa controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/controllers/pwa_controller.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/controllers/pwa_controller.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for manifest view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/pwa/manifest.json.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/pwa/manifest.json.erb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for service worker view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/pwa/service-worker.js.erb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for offline page" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/pwa/offline.html.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/pwa/offline.html.erb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for registration js" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/javascript/pwa/registration.js"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/javascript/pwa/registration.js"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for routes" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes.scan("pwa#manifest").length).to eq(1)
    end
  end
end
