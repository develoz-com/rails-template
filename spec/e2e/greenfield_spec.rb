# frozen_string_literal: true

require "spec_helper"
require "open3"
require "fileutils"
require "tmpdir"
require "digest/sha2"

# E2e specs for `develoz new` driving the full greenfield generation pipeline.
#
# These specs invoke the real CLI in a subprocess (via Open3) so that the
# actual `rails new` shell-out and every install generator run end-to-end.
# They are tagged :e2e and :slow so CI can skip them in fast runs:
#
#   bundle exec rspec                       # runs everything (default)
#   bundle exec rspec --tag ~e2e            # skip e2e (fast CI)
#   bundle exec rspec --tag e2e             # only e2e (nightly matrix)
#
RSpec.describe "develoz new (greenfield e2e)", :e2e, :slow do # rubocop:disable RSpec/DescribeClass
  let(:gem_root) { File.expand_path("../..", __dir__) }
  let(:lib_dir) { File.join(gem_root, "lib") }

  def build_command(app_dir, flags)
    flag_args = flags.map(&:inspect).join(", ")
    inner = [
      "require 'develoz'",
      "require 'generators/develoz/install/install_generator'",
      "require 'develoz/cli'",
      "Develoz::CLI.start(['new', #{app_dir.inspect}, '--yes', #{flag_args}])"
    ].join("; ")
    ["ruby", "-I#{lib_dir}", "-e", inner]
  end

  def generate_app(app_dir, flags = [])
    FileUtils.rm_rf(app_dir)
    FileUtils.mkdir_p(File.dirname(app_dir))
    stdout, stderr, status = Open3.capture3(*build_command(app_dir, flags))
    [status.exitstatus, stdout, stderr]
  end

  def read_file(app_dir, rel)
    File.read(File.join(app_dir, rel))
  end

  def file_exists?(app_dir, rel)
    File.exist?(File.join(app_dir, rel))
  end

  def gemfile_content(app_dir)
    read_file(app_dir, "Gemfile")
  end

  def option_values(flags)
    flags.to_h { |flag| [flag.delete_prefix("--").to_sym, true] }
  end

  def selected_entries(flags)
    Develoz::Manifest.for(Develoz::Options.new(**option_values(flags)))
  end

  def expected_documentation_paths(flags)
    selected_entries(flags).map { |entry| "docs/#{entry.documentation_slug}.md" }
  end

  def managed_documentation_paths(app_dir, path)
    content = read_file(app_dir, path)
    block = content.match(
      /#{Regexp.escape(Develoz::Generators::FeatureDocumentation::BEGIN_MARKER)}.*?#{Regexp.escape(Develoz::Generators::FeatureDocumentation::END_MARKER)}/mo
    ).to_s
    block.scan(%r{\(docs/([^)]+\.md)\)}).flatten.map { |target| "docs/#{target}" }
  end

  def feature_documentation_paths(app_dir)
    Develoz::Manifest.all.filter_map do |entry|
      path = "docs/#{entry.documentation_slug}.md"
      path if file_exists?(app_dir, path)
    end
  end

  def file_digests(app_dir)
    paths = Dir.glob("**/*", File::FNM_DOTMATCH, base: app_dir)
               .select { |path| File.file?(File.join(app_dir, path)) }
    paths.index_with { |path| Digest::SHA256.file(File.join(app_dir, path)).hexdigest }
  end

  def rerun_install(app_dir, flags)
    options = option_values(flags)
    Develoz::Generators::InstallGenerator.new([], options, destination_root: app_dir).invoke_all
  end

  shared_examples "core greenfield output" do
    it "exits 0 and announces creation" do
      aggregate_failures do
        expect(exit_status).to eq(0), stderr
        expect(stdout).to match(/Created #{Regexp.escape(app_dir)}/)
      end
    end

    it "creates the Rails app skeleton" do
      aggregate_failures do
        expect(file_exists?(dir, "Gemfile")).to be true
        expect(file_exists?(dir, "config/routes.rb")).to be true
        expect(file_exists?(dir, "config/application.rb")).to be true
        expect(file_exists?(dir, "Rakefile")).to be true
        expect(file_exists?(dir, "config.ru")).to be true
      end
    end

    it "writes .tool-versions with ruby and nodejs" do
      content = read_file(dir, ".tool-versions")
      aggregate_failures do
        expect(content).to match(/^ruby \d+\.\d+\.\d+$/)
        expect(content).to match(/^nodejs \d+\.\d+\.\d+$/)
      end
    end

    it "writes .ruby-version" do
      content = read_file(dir, ".ruby-version")
      expect(content).to match(/^\d+\.\d+\.\d+$/)
    end

    it "injects core gems into the Gemfile" do
      gemfile = read_file(dir, "Gemfile")
      aggregate_failures do
        expect(gemfile).to include('"dotenv-rails"')
        expect(gemfile).to include('"rspec-rails"')
        expect(gemfile).to include('"simplecov"')
        expect(gemfile).to include('"simplecov-lcov"')
        expect(gemfile).to include('"factory_bot_rails"')
        expect(gemfile).to include('"pg"')
        expect(gemfile).to include('"solid_queue"')
        expect(gemfile).to include('"solid_cache"')
        expect(gemfile).to include('"solid_cable"')
      end
    end

    it "injects CI/lint gems into the Gemfile" do
      gemfile = read_file(dir, "Gemfile")
      aggregate_failures do
        expect(gemfile).to include('"rubocop-rails-omakase"')
        expect(gemfile).to include('"reek"')
        expect(gemfile).to include('"brakeman"')
        expect(gemfile).to include('"bundler-audit"')
      end
    end

    it "creates spec/spec_helper.rb with SimpleCov 100% gate" do
      content = read_file(dir, "spec/spec_helper.rb")
      aggregate_failures do
        expect(content).to include('require "simplecov"')
        expect(content).to include('require "simplecov-lcov"')
        expect(content).to include("enable_coverage :branch")
        expect(content).to include("minimum_coverage line: 100, branch: 100")
      end
    end

    it "creates spec/rails_helper.rb" do
      expect(file_exists?(dir, "spec/rails_helper.rb")).to be true
    end

    it "creates .rspec config" do
      expect(file_exists?(dir, ".rspec")).to be true
    end

    it "creates bin/ci entrypoint" do
      expect(file_exists?(dir, "bin/ci")).to be true
    end

    it "creates config/ci.rb with RSpec and lint steps" do
      content = read_file(dir, "config/ci.rb")
      aggregate_failures do
        expect(content).to include("Tests: RSpec (parallel)")
        expect(content).to include("bin/rails spec:parallel")
        expect(content).to include("Style: Ruby")
        expect(content).to include("Security: Brakeman")
      end
    end

    it "creates lint config files" do
      aggregate_failures do
        expect(file_exists?(dir, ".rubocop.yml")).to be true
        expect(file_exists?(dir, ".reek.yml")).to be true
        expect(file_exists?(dir, "biome.json")).to be true
      end
    end

    it "creates Solid Stack config files" do
      aggregate_failures do
        expect(file_exists?(dir, "config/queue.yml")).to be true
        expect(file_exists?(dir, "config/cache.yml")).to be true
        expect(file_exists?(dir, "config/cable.yml")).to be true
        expect(file_exists?(dir, "config/recurring.yml")).to be true
      end
    end

    it "injects the MissionControl jobs route" do
      routes = read_file(dir, "config/routes.rb")
      expect(routes).to include('mount MissionControl::Jobs::Engine, at: "/jobs"')
    end

    it "injects the maintenance tasks route" do
      routes = read_file(dir, "config/routes.rb")
      expect(routes).to include('mount MaintenanceTasks::Engine, at: "/maintenance_tasks"')
    end

    it "creates the database config" do
      expect(file_exists?(dir, "config/database.yml")).to be true
    end

    it "creates the constants initializer" do
      expect(file_exists?(dir, "config/initializers/constants.rb")).to be true
    end

    it "injects APP_VERSION constant" do
      content = read_file(dir, "config/initializers/constants.rb")
      expect(content).to include('APP_VERSION = ENV.fetch("APP_VERSION", "dev")')
    end

    it "creates the application job" do
      expect(file_exists?(dir, "app/jobs/application_job.rb")).to be true
    end

    it "creates AGENTS.md" do
      expect(file_exists?(dir, "AGENTS.md")).to be true
    end

    it "creates exactly the selected feature guides and managed links" do
      expected_paths = expected_documentation_paths(flags)

      aggregate_failures do
        expect(feature_documentation_paths(dir)).to eq(expected_paths)
        expect(managed_documentation_paths(dir, "README.md")).to eq(expected_paths)
        expect(managed_documentation_paths(dir, "AGENTS.md")).to eq(expected_paths)
        expect(expected_paths).to all(satisfy { |path| file_exists?(dir, path) })
      end
    end

    it "retains the Rails README and generates the full AGENTS template" do
      aggregate_failures do
        expect(read_file(dir, "README.md")).to include("This README would normally document")
        expect(read_file(dir, "AGENTS.md")).to include("Development Environment", "Quality Expectations")
      end
    end

    it "is byte-identical after a second install" do
      first_run = file_digests(dir)

      rerun_install(dir, flags)

      expect(file_digests(dir)).to eq(first_run)
    end

    it "creates .env and .env.example and gitignores .env" do
      aggregate_failures do
        expect(file_exists?(dir, ".env")).to be true
        expect(file_exists?(dir, ".env.example")).to be true
        expect(read_file(dir, ".gitignore")).to include(".env")
      end
    end

    it "creates VSCode settings" do
      expect(file_exists?(dir, ".vscode/settings.json")).to be true
    end
  end

  describe "default (core only)" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:app_dir) { File.join(Dir.tmpdir, "develoz_e2e_default_#{SecureRandom.hex(8)}") }
    let(:dir) { app_dir }
    let(:exit_status) { generation_result[0] }
    let(:stdout) { generation_result[1] }
    let(:stderr) { generation_result[2] }
    let(:generation_result) { generate_app(app_dir) }
    let(:flags) { [] }

    before { generation_result }

    after { FileUtils.rm_rf(app_dir) }

    it_behaves_like "core greenfield output"

    it "does not add API gems by default" do
      expect(gemfile_content(app_dir)).not_to include('"blueprinter"')
    end

    it "does not add auth user model by default" do
      expect(file_exists?(app_dir, "app/models/user.rb")).to be false
    end

    it "does not add docker files by default" do
      expect(file_exists?(app_dir, "docker-compose.yml")).to be false
    end
  end

  describe "flags-heavy (--api --auth --ui --admin --pwa --push --docker --kamal --db_backup)" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:app_dir) { File.join(Dir.tmpdir, "develoz_e2e_full_#{SecureRandom.hex(8)}") }
    let(:dir) { app_dir }
    let(:flags) do
      %w[--api --auth --ui --admin --pwa --push --docker --kamal --db_backup]
    end
    let(:exit_status) { generation_result[0] }
    let(:stdout) { generation_result[1] }
    let(:stderr) { generation_result[2] }
    let(:generation_result) { generate_app(app_dir, flags) }

    before { generation_result }

    after { FileUtils.rm_rf(app_dir) }

    it_behaves_like "core greenfield output"

    it "adds API gems and routes" do
      gemfile = read_file(app_dir, "Gemfile")
      routes = read_file(app_dir, "config/routes.rb")
      aggregate_failures do
        expect(gemfile).to include('"blueprinter"')
        expect(gemfile).to include('"rswag-api"')
        expect(gemfile).to include('"rswag-ui"')
        expect(routes).to include("mount Rswag::Ui::Engine => '/api-docs'")
        expect(routes).to include("mount Rswag::Api::Engine => '/api-docs'")
      end
    end

    it "creates the API base controller" do
      expect(file_exists?(app_dir, "app/controllers/api/v1/base_controller.rb")).to be true
    end

    it "adds auth gems, models, and routes" do
      routes = read_file(app_dir, "config/routes.rb")
      aggregate_failures do
        expect(gemfile_content(app_dir)).to include('"bcrypt"')
        expect(file_exists?(app_dir, "app/models/user.rb")).to be true
        expect(file_exists?(app_dir, "app/models/current.rb")).to be true
        expect(routes).to include("resource :session")
        expect(routes).to include("resources :passwords")
      end
    end

    it "wires develoz-ui submodule and importmap pins" do
      aggregate_failures do
        expect(file_exists?(app_dir, ".gitmodules")).to be true
        expect(read_file(app_dir, ".gitmodules")).to include("vendor/develoz-ui")
        expect(read_file(app_dir, "config/importmap.rb")).to include('pin "develoz-ui"')
        expect(file_exists?(app_dir, "bin/setup_develoz_ui")).to be true
      end
    end

    it "creates the admin namespace controller and route" do
      aggregate_failures do
        expect(file_exists?(app_dir, "app/controllers/admin/base_controller.rb")).to be true
        expect(file_exists?(app_dir, "app/controllers/admin/dashboard_controller.rb")).to be true
        expect(read_file(app_dir, "config/routes.rb")).to include("namespace :admin")
      end
    end

    it "creates PWA controller and views" do
      aggregate_failures do
        expect(file_exists?(app_dir, "app/controllers/pwa_controller.rb")).to be true
        expect(file_exists?(app_dir, "app/views/pwa/manifest.json.erb")).to be true
        expect(file_exists?(app_dir, "app/views/pwa/service-worker.js.erb")).to be true
      end
    end

    it "adds push notification model, service, and gem" do
      aggregate_failures do
        expect(file_exists?(app_dir, "app/models/push_subscription.rb")).to be true
        expect(file_exists?(app_dir, "app/services/push_notification_service.rb")).to be true
        expect(gemfile_content(app_dir)).to include('"web-push"')
      end
    end

    it "orders PWA before Push documentation" do
      paths = managed_documentation_paths(app_dir, "README.md")

      expect(paths.index("docs/pwa.md")).to be < paths.index("docs/push.md")
    end

    it "appends VAPID env vars" do
      env = read_file(app_dir, ".env")
      aggregate_failures do
        expect(env).to include("VAPID_PUBLIC_KEY=")
        expect(env).to include("VAPID_PRIVATE_KEY=")
        expect(env).to include("VAPID_SUBJECT=")
      end
    end

    it "creates docker compose, dev dockerfile, and bin scripts" do
      aggregate_failures do
        expect(file_exists?(app_dir, "docker-compose.yml")).to be true
        expect(file_exists?(app_dir, "Dockerfile.dev")).to be true
        expect(file_exists?(app_dir, "bin/dev")).to be true
        expect(file_exists?(app_dir, "bin/setup")).to be true
      end
    end

    it "wires docker env vars" do
      env = read_file(app_dir, ".env")
      aggregate_failures do
        expect(env).to include("POSTGRES_USER=postgres")
        expect(env).to include("DATABASE_URL=postgres://")
      end
    end

    it "creates kamal deploy config and production dockerfile" do
      aggregate_failures do
        expect(file_exists?(app_dir, "config/deploy.yml")).to be true
        expect(file_exists?(app_dir, "Dockerfile.prod")).to be true
        expect(file_exists?(app_dir, ".kamal/secrets")).to be true
        expect(read_file(app_dir, ".gitignore")).to include(".kamal/secrets")
      end
    end

    it "creates db-backup script and rake task" do
      aggregate_failures do
        expect(file_exists?(app_dir, "bin/db-backup")).to be true
        expect(file_exists?(app_dir, "lib/tasks/backup.rake")).to be true
        expect(read_file(app_dir, ".gitignore")).to include("/backups/")
      end
    end
  end
end
