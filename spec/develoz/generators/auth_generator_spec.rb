# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/auth/auth_generator"

RSpec.describe Develoz::Generators::AuthGenerator do
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
    gen.add_bcrypt_gem
    gen.create_user_model
    gen.create_current_model
    gen.create_authentication_concern
    gen.create_sessions_controller
    gen.create_passwords_controller
    gen.create_passwords_mailer
    gen.create_sessions_views
    gen.create_passwords_views
    gen.create_passwords_mailer_views
    gen.create_users_migration
    gen.insert_auth_routes
    gen.create_sessions_request_spec
    gen.create_passwords_request_spec
    gen
  end

  def migration_path(tmp_dir)
    migrations = Dir.glob(File.join(tmp_dir, "db/migrate/*_create_users.rb"))
    expect(migrations).not_to be_empty
    migrations.first
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds bcrypt gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("bcrypt")
    end
  end

  it "generates user model" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/user.rb"))
    end
  end

  it "user model has has_secure_password" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/user.rb"))
      expect(content).to include("has_secure_password")
    end
  end

  it "user model normalizes email" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/user.rb"))
      expect(content).to include("normalizes :email")
    end
  end

  it "user model validates email" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/user.rb"))
      expect(content).to include("validates :email")
    end
  end

  it "user model has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/user.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates current model" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/current.rb"))
    end
  end

  it "current model has attribute :user" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/current.rb"))
      expect(content).to include("attribute :user")
    end
  end

  it "current model inherits from CurrentAttributes" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/current.rb"))
      expect(content).to include("Current < ActiveSupport::CurrentAttributes")
    end
  end

  it "generates authentication concern" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/controllers/concerns/authentication.rb"))
    end
  end

  it "authentication concern has before_action :require_authentication" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/concerns/authentication.rb"))
      expect(content).to include("before_action :require_authentication")
    end
  end

  it "authentication concern has resume_session" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/concerns/authentication.rb"))
      expect(content).to include("def resume_session")
    end
  end

  it "authentication concern has request_authentication" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/concerns/authentication.rb"))
      expect(content).to include("def request_authentication")
    end
  end

  it "authentication concern has after_authentication_url" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/concerns/authentication.rb"))
      expect(content).to include("def after_authentication_url")
    end
  end

  it "authentication concern has allow_authentication_as" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/concerns/authentication.rb"))
      expect(content).to include("def allow_authentication_as")
    end
  end

  it "authentication concern has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/concerns/authentication.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates sessions controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/controllers/sessions_controller.rb"))
    end
  end

  it "sessions controller has new create destroy" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/sessions_controller.rb"))
      expect(content).to include("def new")
      expect(content).to include("def create")
      expect(content).to include("def destroy")
    end
  end

  it "sessions controller has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/sessions_controller.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates passwords controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/controllers/passwords_controller.rb"))
    end
  end

  it "passwords controller has edit update" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/passwords_controller.rb"))
      expect(content).to include("def edit")
      expect(content).to include("def update")
    end
  end

  it "passwords controller has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/controllers/passwords_controller.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates passwords mailer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/mailers/passwords_mailer.rb"))
    end
  end

  it "passwords mailer has reset method" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/mailers/passwords_mailer.rb"))
      expect(content).to include("def reset")
    end
  end

  it "passwords mailer has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/mailers/passwords_mailer.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "generates sessions new view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/sessions/new.html.erb"))
    end
  end

  it "sessions new view has form_with" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/sessions/new.html.erb"))
      expect(content).to include("form_with")
    end
  end

  it "generates passwords edit view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/passwords/edit.html.erb"))
    end
  end

  it "passwords edit view has form_with" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/passwords/edit.html.erb"))
      expect(content).to include("form_with")
    end
  end

  it "generates passwords mailer reset view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/views/passwords_mailer/reset.html.erb"))
    end
  end

  it "passwords mailer reset view has reset link" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/views/passwords_mailer/reset.html.erb"))
      expect(content).to include("edit_password_url")
    end
  end

  it "generates users migration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(migration_path(tmp))
    end
  end

  it "migration has email column" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to include("t.string :email")
    end
  end

  it "migration has password_digest column" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to include("t.string :password_digest")
    end
  end

  it "migration has unique index on email" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to include("add_index :users, :email, unique: true")
    end
  end

  it "migration has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "inserts session route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include("resource :session")
    end
  end

  it "inserts passwords route" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include("resources :passwords, param: :token")
    end
  end

  it "generates sessions request spec" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/requests/sessions_spec.rb"))
    end
  end

  it "sessions request spec has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/sessions_spec.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "sessions request spec describes Sessions" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/sessions_spec.rb"))
      expect(content).to include('describe "Sessions"')
    end
  end

  it "generates passwords request spec" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/requests/passwords_spec.rb"))
    end
  end

  it "passwords request spec has frozen_string_literal" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/passwords_spec.rb"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "passwords request spec describes Passwords" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/requests/passwords_spec.rb"))
      expect(content).to include('describe "Passwords"')
    end
  end

  it "is idempotent for bcrypt gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan(/^\s*gem\s+["']bcrypt["']/m).length).to eq(1)
    end
  end

  it "is idempotent for user model" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/models/user.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/models/user.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for current model" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/models/current.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/models/current.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for authentication concern" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/controllers/concerns/authentication.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/controllers/concerns/authentication.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for sessions controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/controllers/sessions_controller.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/controllers/sessions_controller.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for passwords controller" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/controllers/passwords_controller.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/controllers/passwords_controller.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for passwords mailer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/mailers/passwords_mailer.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/mailers/passwords_mailer.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for sessions view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/sessions/new.html.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/sessions/new.html.erb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for passwords view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/passwords/edit.html.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/passwords/edit.html.erb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for mailer view" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/views/passwords_mailer/reset.html.erb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/views/passwords_mailer/reset.html.erb"))
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

  it "is idempotent for routes" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes.scan("resource :session").length).to eq(1)
    end
  end

  it "is idempotent for sessions request spec" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/requests/sessions_spec.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/requests/sessions_spec.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for passwords request spec" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/requests/passwords_spec.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/requests/passwords_spec.rb"))
      expect(first).to eq(second)
    end
  end
end
