# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/db_backup/db_backup_generator"

RSpec.describe Develoz::Generators::DbBackupGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".gitignore"), "/log/\n/tmp/\n")
      FileUtils.mkdir_p(File.join(dir, "bin"))
      yield dir
    end
  end

  def seed_compose(dir)
    File.write(File.join(dir, "docker-compose.yml"), "services:\n  postgres:\n    image: postgres:18\n")
  end

  def run_gen(tmp_dir, opts = {})
    gen = described_class.new([], opts, destination_root: tmp_dir)
    gen.create_backup_script
    gen.create_backup_rake
    gen.inject_compose_service
    gen.ensure_backups_gitignored
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "generates bin/db-backup script" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "bin/db-backup"))
    end
  end

  it "makes bin/db-backup executable" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      mode = File.stat(File.join(tmp, "bin/db-backup")).mode & 0o777
      expect(mode).to eq(0o755)
    end
  end

  it "bin/db-backup uses pg_dump with gzip" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/db-backup"))
      expect(content).to include("pg_dump")
      expect(content).to include("gzip")
      expect(content).to include(".sql.gz")
    end
  end

  it "bin/db-backup has retention pruning" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/db-backup"))
      expect(content).to include("RETENTION_DAYS")
      expect(content).to include("find")
      expect(content).to include("-delete")
    end
  end

  it "generates lib/tasks/backup.rake" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "lib/tasks/backup.rake"))
    end
  end

  it "rake task has backup namespace with create and prune tasks" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "lib/tasks/backup.rake"))
      expect(content).to include("namespace :backup do")
      expect(content).to include("task create:")
      expect(content).to include("task prune:")
    end
  end

  it "rake task has frozen_string_literal comment" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "lib/tasks/backup.rake"))
      expect(content).to start_with("# frozen_string_literal: true")
    end
  end

  it "rake task references retention env var" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "lib/tasks/backup.rake"))
      expect(content).to include("BACKUP_RETENTION_DAYS")
    end
  end

  it "adds /backups/ to .gitignore" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".gitignore"))
      expect(content).to include("/backups/")
    end
  end

  it "does not inject compose service when docker is false" do
    with_tmp_dir do |tmp|
      seed_compose(tmp)
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).not_to include("db-backup")
    end
  end

  it "does not inject compose service when docker is unset" do
    with_tmp_dir do |tmp|
      seed_compose(tmp)
      run_gen(tmp, {})
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).not_to include("db-backup")
    end
  end

  it "injects compose service when docker is true" do
    with_tmp_dir do |tmp|
      seed_compose(tmp)
      run_gen(tmp, "docker" => true)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("db-backup:")
      expect(content).to include("# db-backup service (develoz:db_backup)")
    end
  end

  it "compose service runs backups every 6 hours" do
    with_tmp_dir do |tmp|
      seed_compose(tmp)
      run_gen(tmp, "docker" => true)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("21600")
    end
  end

  it "compose service has retention env var" do
    with_tmp_dir do |tmp|
      seed_compose(tmp)
      run_gen(tmp, "docker" => true)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("BACKUP_RETENTION_DAYS")
    end
  end

  it "compose service depends on postgres" do
    with_tmp_dir do |tmp|
      seed_compose(tmp)
      run_gen(tmp, "docker" => true)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("depends_on")
      expect(content).to include("postgres")
    end
  end

  it "preserves existing compose services" do
    with_tmp_dir do |tmp|
      seed_compose(tmp)
      run_gen(tmp, "docker" => true)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("postgres:")
      expect(content).to include("image: postgres:18")
    end
  end

  it "is idempotent for bin/db-backup" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "bin/db-backup"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "bin/db-backup"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for rake task" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "lib/tasks/backup.rake"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "lib/tasks/backup.rake"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for gitignore" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      content = File.read(File.join(tmp, ".gitignore"))
      expect(content.scan("/backups/").size).to eq(1)
    end
  end

  it "is idempotent for compose service injection" do
    with_tmp_dir do |tmp|
      seed_compose(tmp)
      run_gen(tmp, "docker" => true)
      run_gen(tmp, "docker" => true)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content.scan("db-backup:").size).to eq(1)
    end
  end

  it "preserves executable bit on re-run" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      mode = File.stat(File.join(tmp, "bin/db-backup")).mode & 0o777
      expect(mode).to eq(0o755)
    end
  end
end
