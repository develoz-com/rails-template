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
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.create_concerns
    gen.create_migrations
    gen.create_concern_specs
    gen
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
    end
  end

  it "generates add_status_transitions migration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "db/migrate/add_status_transitions.rb"))
    end
  end

  it "add_status_transitions migration adds status column" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "db/migrate/add_status_transitions.rb"))
      expect(content).to include("add_column :records, :status, :string")
    end
  end

  it "add_status_transitions migration adds status_transitions jsonb column" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "db/migrate/add_status_transitions.rb"))
      expect(content).to include("add_column :records, :status_transitions, :jsonb")
    end
  end

  it "generates create_configurations migration" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "db/migrate/create_configurations.rb"))
    end
  end

  it "create_configurations migration creates configurations table" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "db/migrate/create_configurations.rb"))
      expect(content).to include("create_table :configurations")
    end
  end

  it "create_configurations migration uses uuid primary key" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "db/migrate/create_configurations.rb"))
      expect(content).to include("id: :uuid")
    end
  end

  it "create_configurations migration includes polymorphic columns" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "db/migrate/create_configurations.rb"))
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
      first = File.read(File.join(tmp, "db/migrate/create_configurations.rb"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "db/migrate/create_configurations.rb"))
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
