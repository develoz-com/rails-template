# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/docker/docker_generator"

RSpec.describe Develoz::Generators::DockerGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      File.write(File.join(dir, ".gitignore"), "/log\n")
      File.write(File.join(dir, ".env"), "APP_NAME=test\n")
      File.write(File.join(dir, ".env.example"), "APP_NAME=\n")
      yield dir
    end
  end

  def run_gen(tmp_dir)
    gen = described_class.new([], {}, destination_root: tmp_dir)
    gen.create_docker_compose
    gen.create_dockerfile_dev
    gen.create_bin_dev
    gen.create_bin_setup
    gen.create_bin_docker_entrypoint
    gen.wire_env
    gen.ensure_env_gitignored
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "generates docker-compose.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "docker-compose.yml"))
    end
  end

  it "docker-compose.yml has app service" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("app:")
    end
  end

  it "docker-compose.yml has postgres service" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("postgres:")
    end
  end

  it "docker-compose.yml has selenium service" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("selenium:")
    end
  end

  it "docker-compose.yml has mailcatcher service" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("mailcatcher:")
    end
  end

  it "docker-compose.yml does not include analyzer container" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).not_to include("analyzer:")
    end
  end

  it "docker-compose.yml does not include implementation container" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).not_to include("implementation:")
    end
  end

  it "docker-compose.yml does not include opencode container" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).not_to include("opencode:")
    end
  end

  it "docker-compose.yml references Dockerfile.dev" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("Dockerfile.dev")
    end
  end

  it "docker-compose.yml references docker-entrypoint" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "docker-compose.yml"))
      expect(content).to include("bin/docker-entrypoint")
    end
  end

  it "generates Dockerfile.dev" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "Dockerfile.dev"))
    end
  end

  it "Dockerfile.dev has FROM ruby" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.dev"))
      expect(content).to include("FROM ruby:")
    end
  end

  it "Dockerfile.dev installs libpq-dev" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.dev"))
      expect(content).to include("libpq-dev")
    end
  end

  it "Dockerfile.dev sets WORKDIR /rails" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.dev"))
      expect(content).to include("WORKDIR /rails")
    end
  end

  it "Dockerfile.dev exposes port 3000" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.dev"))
      expect(content).to include("EXPOSE 3000")
    end
  end

  it "generates bin/dev" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "bin/dev"))
    end
  end

  it "bin/dev has shebang" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/dev"))
      expect(content).to start_with("#!/usr/bin/env bash")
    end
  end

  it "bin/dev runs docker compose up" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/dev"))
      expect(content).to include("docker compose up")
    end
  end

  it "bin/dev is executable" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      mode = File.stat(File.join(tmp, "bin/dev")).mode & 0o755
      expect(mode).to eq(0o755)
    end
  end

  it "generates bin/setup" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "bin/setup"))
    end
  end

  it "bin/setup has shebang" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/setup"))
      expect(content).to start_with("#!/usr/bin/env bash")
    end
  end

  it "bin/setup runs bundle install" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/setup"))
      expect(content).to include("bundle install")
    end
  end

  it "bin/setup is executable" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      mode = File.stat(File.join(tmp, "bin/setup")).mode & 0o755
      expect(mode).to eq(0o755)
    end
  end

  it "generates bin/docker-entrypoint" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "bin/docker-entrypoint"))
    end
  end

  it "bin/docker-entrypoint has shebang" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/docker-entrypoint"))
      expect(content).to start_with("#!/usr/bin/env bash")
    end
  end

  it "bin/docker-entrypoint removes server.pid" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/docker-entrypoint"))
      expect(content).to include("server.pid")
    end
  end

  it "bin/docker-entrypoint starts rails server on 0.0.0.0" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "bin/docker-entrypoint"))
      expect(content).to include("-b 0.0.0.0")
      expect(content).to include("-p 3000")
    end
  end

  it "bin/docker-entrypoint is executable" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      mode = File.stat(File.join(tmp, "bin/docker-entrypoint")).mode & 0o755
      expect(mode).to eq(0o755)
    end
  end

  it "wires POSTGRES_USER into .env" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env).to include("POSTGRES_USER=postgres")
    end
  end

  it "wires POSTGRES_PASSWORD into .env" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env).to include("POSTGRES_PASSWORD=postgres")
    end
  end

  it "wires DATABASE_URL into .env" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env).to include("DATABASE_URL=postgres://postgres:postgres@postgres:5432/")
    end
  end

  it "wires SELENIUM_URL into .env" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env).to include("SELENIUM_URL=http://selenium:4444")
    end
  end

  it "wires MAILCATCHER_URL into .env" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env).to include("MAILCATCHER_URL=http://mailcatcher:1080")
    end
  end

  it "wires POSTGRES_DB with app name into .env" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env).to include("POSTGRES_DB=#{File.basename(tmp)}_development")
    end
  end

  it "adds .env to .gitignore" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gitignore = File.read(File.join(tmp, ".gitignore"))
      expect(gitignore).to include(".env")
    end
  end

  it "is idempotent for docker-compose.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "docker-compose.yml"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "docker-compose.yml"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for Dockerfile.dev" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "Dockerfile.dev"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "Dockerfile.dev"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for bin/dev" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "bin/dev"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "bin/dev"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for bin/setup" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "bin/setup"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "bin/setup"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for bin/docker-entrypoint" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "bin/docker-entrypoint"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "bin/docker-entrypoint"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for .env keys" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      env = File.read(File.join(tmp, ".env"))
      expect(env.scan("POSTGRES_USER=postgres").size).to eq(1)
      expect(env.scan("DATABASE_URL=").size).to eq(1)
    end
  end

  it "is idempotent for .gitignore" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gitignore = File.read(File.join(tmp, ".gitignore"))
      expect(gitignore.scan(/^\.env$/).size).to eq(1)
    end
  end

  it "appends env keys to .env.example" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      example = File.read(File.join(tmp, ".env.example"))
      expect(example).to include("POSTGRES_USER=")
      expect(example).to include("DATABASE_URL=")
    end
  end

  it "is idempotent for .env.example keys" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      example = File.read(File.join(tmp, ".env.example"))
      expect(example.scan("POSTGRES_USER=").size).to eq(1)
    end
  end
end
