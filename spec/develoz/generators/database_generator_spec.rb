# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/database/database_generator"

RSpec.describe Develoz::Generators::DatabaseGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.add_database_gems
    gen.create_database_config
    gen.create_pg_search_initializer
    gen.create_pg_extensions_migration
    gen.ensure_postgres_tool_version
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds pg gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include('gem "pg"')
    end
  end

  it "adds pg_search gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include('gem "pg_search"')
    end
  end

  it "generates config/database.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/database.yml"))
    end
  end

  it "database.yml uses postgresql adapter" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      db_yml = File.read(File.join(tmp, "config/database.yml"))
      expect(db_yml).to include("adapter: postgresql")
    end
  end

  it "database.yml includes TEST_ENV_NUMBER suffix for test" do
    with_tmp_dir do |tmp|
      ENV["TEST_ENV_NUMBER"] = "-1"
      begin
        run_gen(tmp)
        db_yml = File.read(File.join(tmp, "config/database.yml"))
        expect(db_yml).to include("_test-1")
      ensure
        ENV.delete("TEST_ENV_NUMBER")
      end
    end
  end

  it "database.yml includes solid queue named connection" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      db_yml = File.read(File.join(tmp, "config/database.yml"))
      expect(db_yml).to include("queue:")
      expect(db_yml).to include("_queue_")
    end
  end

  it "database.yml includes solid cache named connection" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      db_yml = File.read(File.join(tmp, "config/database.yml"))
      expect(db_yml).to include("cache:")
      expect(db_yml).to include("_cache_")
    end
  end

  it "database.yml includes solid cable named connection" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      db_yml = File.read(File.join(tmp, "config/database.yml"))
      expect(db_yml).to include("cable:")
      expect(db_yml).to include("_cable_")
    end
  end

  it "database.yml includes DATABASE_URL pattern for production" do
    with_tmp_dir do |tmp|
      ENV["DATABASE_URL"] = "postgres://user:pass@host:5432/db"
      begin
        run_gen(tmp)
        db_yml = File.read(File.join(tmp, "config/database.yml"))
        expect(db_yml).to include("postgres://user:pass@host:5432/db")
      ensure
        ENV.delete("DATABASE_URL")
      end
    end
  end

  it "database.yml documents PostgreSQL 18+ requirement" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      db_yml = File.read(File.join(tmp, "config/database.yml"))
      expect(db_yml).to include("PostgreSQL 18")
    end
  end

  it "database.yml includes development environment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      db_yml = File.read(File.join(tmp, "config/database.yml"))
      expect(db_yml).to include("development:")
    end
  end

  it "database.yml includes test environment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      db_yml = File.read(File.join(tmp, "config/database.yml"))
      expect(db_yml).to include("test:")
    end
  end

  it "database.yml includes production environment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      db_yml = File.read(File.join(tmp, "config/database.yml"))
      expect(db_yml).to include("production:")
    end
  end

  it "generates config/initializers/pg_search.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/initializers/pg_search.rb"))
    end
  end

  it "pg_search initializer has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      pg_init = File.read(File.join(tmp, "config/initializers/pg_search.rb"))
      expect(pg_init).to start_with("# frozen_string_literal: true")
    end
  end

  it "pg_search initializer references searchable concern" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      pg_init = File.read(File.join(tmp, "config/initializers/pg_search.rb"))
      expect(pg_init).to include("searchable")
    end
  end

  it "generates the PostgreSQL extensions migration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      migration = File.read(File.join(tmp, "db/migrate/create_pg_extensions.rb"))
      expect(migration).to include("class CreatePgExtensions < ActiveRecord::Migration[8.0]")
      aggregate_failures do
        expect(migration).to include("CREATE EXTENSION IF NOT EXISTS pg_trgm")
        expect(migration).to include("CREATE EXTENSION IF NOT EXISTS unaccent")
        expect(migration).to include("DROP EXTENSION IF EXISTS unaccent")
        expect(migration).to include("DROP EXTENSION IF EXISTS pg_trgm")
      end
    end
  end

  it "creates .tool-versions when it does not exist" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      tool = File.read(File.join(tmp, ".tool-versions"))
      expect(tool).to include("postgres 18")
    end
  end

  it "appends postgres to existing .tool-versions" do
    with_tmp_dir do |tmp|
      File.write(File.join(tmp, ".tool-versions"), "ruby 4.0.5\nnodejs 24.15.0\n")
      run_gen(tmp)
      tool = File.read(File.join(tmp, ".tool-versions"))
      expect(tool).to include("ruby 4.0.5")
      expect(tool).to include("postgres 18")
      expect(tool).to include("nodejs 24.15.0")
    end
  end

  it "is idempotent for gems" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan('gem "pg"').size).to eq(1)
      expect(gemfile.scan('gem "pg_search"').size).to eq(1)
    end
  end

  it "is idempotent for database.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/database.yml"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/database.yml"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for pg_search initializer" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/initializers/pg_search.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/initializers/pg_search.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for .tool-versions when file is created" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      tool = File.read(File.join(tmp, ".tool-versions"))
      expect(tool.scan("postgres 18").size).to eq(1)
    end
  end

  it "is idempotent for .tool-versions when file pre-exists" do
    with_tmp_dir do |tmp|
      File.write(File.join(tmp, ".tool-versions"), "ruby 4.0.5\n")
      run_gen(tmp)
      run_gen(tmp)
      tool = File.read(File.join(tmp, ".tool-versions"))
      expect(tool.scan("postgres 18").size).to eq(1)
    end
  end
end
