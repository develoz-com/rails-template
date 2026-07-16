# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/push/push_generator"

RSpec.describe Develoz::Generators::PushGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
      File.write(File.join(dir, ".env"), "APP_NAME=test\n")
      File.write(File.join(dir, ".env.example"), "APP_NAME=\n")
      File.write(File.join(dir, ".gitignore"), "/log\n")
      yield dir
    end
  end

  def run_gen(tmp_dir, pwa: true)
    gen = described_class.new([], { pwa: pwa }, destination_root: tmp_dir)
    gen.ensure_pwa_prerequisite
    gen.add_web_push_gem
    gen.create_push_subscription_model
    gen.create_push_subscription_migration
    gen.create_push_notification_service
    gen.create_service_worker_push_handlers
    gen.create_subscription_js
    gen.append_vapid_env
    gen
  end

  def migration_path(tmp_dir)
    migrations = Dir.glob(File.join(tmp_dir, "db/migrate/*_create_push_subscriptions.rb"))
    expect(migrations).not_to be_empty
    migrations.first
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds web-push gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include('gem "web-push"')
    end
  end

  it "generates push subscription model" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/push_subscription.rb"))
    end
  end

  it "push subscription model has endpoint validation" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/push_subscription.rb"))
      expect(content).to include("validates :endpoint, presence: true, uniqueness: true")
    end
  end

  it "push subscription model has p256dh validation" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/push_subscription.rb"))
      expect(content).to include("validates :p256dh, presence: true")
    end
  end

  it "push subscription model has auth validation" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/push_subscription.rb"))
      expect(content).to include("validates :auth, presence: true")
    end
  end

  it "push subscription model belongs to user" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/push_subscription.rb"))
      expect(content).to include("belongs_to :user")
    end
  end

  it "push subscription model has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/push_subscription.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates push subscriptions migration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(migration_path(tmp))
    end
  end

  it "migration creates push_subscriptions table" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to include("create_table :push_subscriptions")
    end
  end

  it "migration has endpoint column" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to include("t.string :endpoint")
    end
  end

  it "migration has p256dh column" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to include("t.string :p256dh")
    end
  end

  it "migration has auth column" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to include("t.string :auth")
    end
  end

  it "migration has user reference" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to include("t.references :user")
    end
  end

  it "migration has unique index on endpoint" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to include("add_index :push_subscriptions, :endpoint, unique: true")
    end
  end

  it "migration has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates push notification service" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/services/push_notification_service.rb"))
    end
  end

  it "push notification service requires web-push" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/services/push_notification_service.rb"))
      expect(content).to include('require "web-push"')
    end
  end

  it "push notification service has send_notification method" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/services/push_notification_service.rb"))
      expect(content).to include("def self.send_notification")
    end
  end

  it "push notification service uses WebPush.payload_send" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/services/push_notification_service.rb"))
      expect(content).to include("WebPush.payload_send")
    end
  end

  it "push notification service reads VAPID keys from ENV" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/services/push_notification_service.rb"))
      expect(content).to include('ENV.fetch("VAPID_PUBLIC_KEY")')
      expect(content).to include('ENV.fetch("VAPID_PRIVATE_KEY")')
    end
  end

  it "push notification service has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/services/push_notification_service.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates service worker push handlers" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/pwa/sw_push_handlers.js"))
    end
  end

  it "sw push handlers has push event listener" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/sw_push_handlers.js"))
      expect(content).to include('addEventListener("push"')
    end
  end

  it "sw push handlers has notificationclick event listener" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/sw_push_handlers.js"))
      expect(content).to include('addEventListener("notificationclick"')
    end
  end

  it "sw push handlers shows notification" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/sw_push_handlers.js"))
      expect(content).to include("showNotification")
    end
  end

  it "sw push handlers handles notification click" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/sw_push_handlers.js"))
      expect(content).to include("notificationclick")
    end
  end

  it "sw push handlers parses JSON payload" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/pwa/sw_push_handlers.js"))
      expect(content).to include("event.data.json()")
    end
  end

  it "generates subscription js" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/javascript/pwa/subscription.js"))
    end
  end

  it "subscription js subscribes to push manager" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/javascript/pwa/subscription.js"))
      expect(content).to include("pushManager.subscribe")
    end
  end

  it "subscription js uses applicationServerKey" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/javascript/pwa/subscription.js"))
      expect(content).to include("applicationServerKey")
    end
  end

  it "subscription js uses userVisibleOnly" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/javascript/pwa/subscription.js"))
      expect(content).to include("userVisibleOnly")
    end
  end

  it "subscription js has urlBase64ToUint8Array helper" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/javascript/pwa/subscription.js"))
      expect(content).to include("urlBase64ToUint8Array")
    end
  end

  it "subscription js exports subscribeToPush" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/javascript/pwa/subscription.js"))
      expect(content).to include("export { subscribeToPush }")
    end
  end

  it "appends VAPID_PUBLIC_KEY to .env" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env).to include("VAPID_PUBLIC_KEY=")
    end
  end

  it "appends VAPID_PRIVATE_KEY to .env" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env).to include("VAPID_PRIVATE_KEY=")
    end
  end

  it "appends VAPID_SUBJECT to .env" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env).to include("VAPID_SUBJECT=mailto:noreply@example.com")
    end
  end

  it "appends VAPID keys to .env.example" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      example = File.read(File.join(tmp, ".env.example"))
      expect(example).to include("VAPID_PUBLIC_KEY=")
      expect(example).to include("VAPID_PRIVATE_KEY=")
      expect(example).to include("VAPID_SUBJECT=")
    end
  end

  it "does not commit real VAPID key values in .env.example" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      example = File.read(File.join(tmp, ".env.example"))
      # .env.example should have empty values (placeholders only)
      expect(example).to include("VAPID_PUBLIC_KEY=\n")
      expect(example).to include("VAPID_PRIVATE_KEY=\n")
    end
  end

  it "is idempotent for web-push gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan(/^\s*gem\s+["']web-push["']/m).length).to eq(1)
    end
  end

  it "is idempotent for push subscription model" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/models/push_subscription.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/models/push_subscription.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for migration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(migration_path(tmp))
      run_gen(tmp)
      second = File.read(migration_path(tmp))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for push notification service" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/services/push_notification_service.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/services/push_notification_service.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for sw push handlers" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/pwa/sw_push_handlers.js"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/pwa/sw_push_handlers.js"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for subscription js" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/javascript/pwa/subscription.js"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/javascript/pwa/subscription.js"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for .env keys" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env.scan("VAPID_PUBLIC_KEY=").size).to eq(1)
      expect(env.scan("VAPID_PRIVATE_KEY=").size).to eq(1)
    end
  end

  it "is idempotent for .env.example keys" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      example = File.read(File.join(tmp, ".env.example"))
      expect(example.scan("VAPID_PUBLIC_KEY=").size).to eq(1)
      expect(example.scan("VAPID_PRIVATE_KEY=").size).to eq(1)
    end
  end

  context "when pwa is not enabled" do
    it "auto-enables pwa by running pwa generator" do
      with_tmp_dir do |tmp|
        gen = described_class.new([], { pwa: false }, destination_root: tmp)
        gen.ensure_pwa_prerequisite
        expect(File).to exist(File.join(tmp, "app/controllers/pwa_controller.rb"))
      end
    end

    it "prints a warning message" do
      with_tmp_dir do |tmp|
        gen = described_class.new([], { pwa: false }, destination_root: tmp)
        expect { gen.ensure_pwa_prerequisite }.to output(/requires --pwa/).to_stdout
      end
    end
  end

  context "when pwa is enabled" do
    it "skips pwa generator invocation" do
      with_tmp_dir do |tmp|
        gen = described_class.new([], { pwa: true }, destination_root: tmp)
        gen.ensure_pwa_prerequisite
        expect(File).not_to exist(File.join(tmp, "app/controllers/pwa_controller.rb"))
      end
    end
  end

  context "when .env does not exist" do
    it "still appends to .env.example" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
        File.write(File.join(dir, ".env.example"), "APP_NAME=\n")
        gen = described_class.new([], { pwa: true }, destination_root: dir)
        gen.append_vapid_env
        example = File.read(File.join(dir, ".env.example"))
        expect(example).to include("VAPID_PUBLIC_KEY=")
      end
    end
  end
end
