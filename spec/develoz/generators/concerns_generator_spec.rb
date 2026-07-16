# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/concerns/concerns_generator"

RSpec.describe Develoz::Generators::ConcernsGenerator do
  # rubocop:disable Style/ExplicitBlockArgument
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      yield dir
    end
  end
  # rubocop:enable Style/ExplicitBlockArgument

  def run_gen(tmp_dir)
    app_record_dir = File.join(tmp_dir, "app/models")
    FileUtils.mkdir_p(app_record_dir)
    File.write(File.join(app_record_dir, "application_record.rb"), <<~RUBY)
      class ApplicationRecord < ActiveRecord::Base
        primary_abstract_class
      end
    RUBY

    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.create_concerns
    gen.create_migrations
    gen.create_concern_specs
    gen.inject_into_application_record
    gen
  end

  def migration_path(tmp_dir, name)
    migrations = Dir.glob(File.join(tmp_dir, "db/migrate/*_#{name}.rb"))
    expect(migrations).not_to be_empty
    migrations.first
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "generates searchable_concern.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/concerns/searchable_concern.rb"))
    end
  end

  it "generates optimized_finders.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/concerns/optimized_finders.rb"))
    end
  end

  it "generates transitionable.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/concerns/transitionable.rb"))
    end
  end

  it "generates configurable.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "app/models/concerns/configurable.rb"))
      expect(File).to exist(File.join(tmp, "app/models/configuration.rb"))
    end
  end

  it "injects concerns into ApplicationRecord" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "app/models/application_record.rb"))
      expect(content).to include("extend SearchableConcern")
      expect(content).to include("include Configurable")
      expect(content).to include("include OptimizedFinders")
    end
  end

  it "generates add_status_transitions migration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(migration_path(tmp, "add_status_transitions"))
    end
  end

  it "add_status_transitions migration adds status column" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp, "add_status_transitions"))
      expect(content).to include("add_column :records, :status, :string")
    end
  end

  it "add_status_transitions migration adds status_transitions jsonb column" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp, "add_status_transitions"))
      expect(content).to include("add_column :records, :status_transitions, :jsonb")
    end
  end

  it "generates create_configurations migration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(migration_path(tmp, "create_configurations"))
    end
  end

  it "create_configurations migration creates configurations table" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp, "create_configurations"))
      expect(content).to include("create_table :configurations")
    end
  end

  it "create_configurations migration uses uuid primary key" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp, "create_configurations"))
      expect(content).to include("id: :uuid")
    end
  end

  it "create_configurations migration includes polymorphic columns" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(migration_path(tmp, "create_configurations"))
      expect(content).to include("configurable_type")
      expect(content).to include("configurable_id")
    end
  end

  it "generates searchable_concern_spec.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/models/concerns/searchable_concern_spec.rb"))
    end
  end

  it "generates optimized_finders_spec.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/models/concerns/optimized_finders_spec.rb"))
    end
  end

  it "generates transitionable_spec.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/models/concerns/transitionable_spec.rb"))
    end
  end

  it "generates configurable_spec.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/models/concerns/configurable_spec.rb"))
    end
  end

  it "generates configuration_spec.rb" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "spec/models/configuration_spec.rb"))
    end
  end

  it "searchable_concern_spec requires rails_helper" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/models/concerns/searchable_concern_spec.rb"))
      expect(content).to include('require "rails_helper"')
    end
  end

  it "transitionable_spec covers state transitions" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/models/concerns/transitionable_spec.rb"))
      expect(content).to include("states")
      expect(content).to include("transitions")
    end
  end

  it "configurable_spec covers config fallback" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "spec/models/concerns/configurable_spec.rb"))
      expect(content).to include("global_fallback")
    end
  end

  it "is idempotent for concern files" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "app/models/concerns/searchable_concern.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "app/models/concerns/searchable_concern.rb"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for migrations" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(migration_path(tmp, "create_configurations"))
      run_gen(tmp)
      second = File.read(migration_path(tmp, "create_configurations"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for spec files" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "spec/models/concerns/configurable_spec.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "spec/models/concerns/configurable_spec.rb"))
      expect(first).to eq(second)
    end
  end
end
