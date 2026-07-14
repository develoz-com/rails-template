# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/develoz/kamal/kamal_generator"

RSpec.describe Develoz::Generators::KamalGenerator do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), "# frozen_string_literal: true\nsource \"https://rubygems.org\"\ngemspec\n")
      File.write(File.join(dir, ".gitignore"), "/coverage/\n")
      yield dir
    end
  end

  def run_gen(tmp_dir, opts = {})
    gen = described_class.new([], opts, destination_root: tmp_dir)
    gen.add_kamal_gem
    gen.create_deploy_config
    gen.create_production_dockerfile
    gen.create_kamal_secrets
    gen.create_postgres_accessory
    gen.ensure_secrets_gitignored
    gen
  end

  it "sets correct destination_root" do
    with_tmp_dir do |tmp|
      gen = run_gen(tmp)
      expect(gen.destination_root).to eq(tmp)
    end
  end

  it "adds kamal gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include("kamal")
    end
  end

  it "generates config/deploy.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/deploy.yml"))
    end
  end

  it "deploy.yml has service name from app_name" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).to include("service:")
    end
  end

  it "deploy.yml has image field" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).to include("image:")
    end
  end

  it "deploy.yml has registry with KAMAL_REGISTRY_PASSWORD" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).to include("registry:")
      expect(content).to include("KAMAL_REGISTRY_PASSWORD")
    end
  end

  it "deploy.yml has servers section" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).to include("servers:")
    end
  end

  it "deploy.yml has default example.com server when no KAMAL_SERVERS" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).to include("example.com")
    end
  end

  it "deploy.yml has postgres accessory" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).to include("accessories:")
      expect(content).to include("postgres:")
      expect(content).to include("postgres:18")
    end
  end

  it "deploy.yml has env secrets for RAILS_MASTER_KEY and DATABASE_URL" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).to include("RAILS_MASTER_KEY")
      expect(content).to include("DATABASE_URL")
    end
  end

  it "deploy.yml does not include VAPID keys without push" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).not_to include("VAPID_PUBLIC_KEY")
      expect(content).not_to include("VAPID_PRIVATE_KEY")
    end
  end

  it "deploy.yml includes VAPID keys when push is enabled" do
    with_tmp_dir do |tmp|
      run_gen(tmp, "push" => true)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).to include("VAPID_PUBLIC_KEY")
      expect(content).to include("VAPID_PRIVATE_KEY")
    end
  end

  it "deploy.yml uses KAMAL_APP_NAME when set" do
    with_tmp_dir do |tmp|
      ENV["KAMAL_APP_NAME"] = "customapp"
      begin
        run_gen(tmp)
        content = File.read(File.join(tmp, "config/deploy.yml"))
        expect(content).to include("service: customapp")
      ensure
        ENV.delete("KAMAL_APP_NAME")
      end
    end
  end

  it "deploy.yml uses KAMAL_IMAGE when set" do
    with_tmp_dir do |tmp|
      ENV["KAMAL_IMAGE"] = "registry/customimage"
      begin
        run_gen(tmp)
        content = File.read(File.join(tmp, "config/deploy.yml"))
        expect(content).to include("image: registry/customimage")
      ensure
        ENV.delete("KAMAL_IMAGE")
      end
    end
  end

  it "deploy.yml uses KAMAL_REGISTRY when set" do
    with_tmp_dir do |tmp|
      ENV["KAMAL_REGISTRY"] = "myregistry"
      begin
        run_gen(tmp)
        content = File.read(File.join(tmp, "config/deploy.yml"))
        expect(content).to include("username: myregistry")
      ensure
        ENV.delete("KAMAL_REGISTRY")
      end
    end
  end

  it "deploy.yml uses KAMAL_SERVERS when set" do
    with_tmp_dir do |tmp|
      ENV["KAMAL_SERVERS"] = "1.2.3.4,5.6.7.8"
      begin
        run_gen(tmp)
        content = File.read(File.join(tmp, "config/deploy.yml"))
        expect(content).to include("- 1.2.3.4")
        expect(content).to include("- 5.6.7.8")
        servers_section = content[/servers:\n(.*?)(?=\n\n|\nregistry)/m, 1]
        expect(servers_section).not_to include("example.com")
      ensure
        ENV.delete("KAMAL_SERVERS")
      end
    end
  end

  it "deploy.yml uses default registry user when KAMAL_REGISTRY empty" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      expect(content).to include("your-registry-user")
    end
  end

  it "generates Dockerfile.prod" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "Dockerfile.prod"))
    end
  end

  it "Dockerfile.prod has multi-stage build" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.prod"))
      expect(content).to include("FROM base AS build")
      expect(content).to include("FROM base")
    end
  end

  it "Dockerfile.prod has production env settings" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.prod"))
      expect(content).to include("RAILS_ENV=\"production\"")
      expect(content).to include("BUNDLE_WITHOUT=\"development\"")
    end
  end

  it "Dockerfile.prod has jemalloc for reduced memory" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.prod"))
      expect(content).to include("libjemalloc")
    end
  end

  it "Dockerfile.prod has postgresql-client" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.prod"))
      expect(content).to include("postgresql-client")
    end
  end

  it "Dockerfile.prod has non-root user" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.prod"))
      expect(content).to include("useradd rails")
      expect(content).to include("USER 1000:1000")
    end
  end

  it "Dockerfile.prod has assets precompile" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.prod"))
      expect(content).to include("assets:precompile")
    end
  end

  it "Dockerfile.prod has Thruster entrypoint" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.prod"))
      expect(content).to include("bin/thrust")
    end
  end

  it "Dockerfile.prod exposes port 80" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "Dockerfile.prod"))
      expect(content).to include("EXPOSE 80")
    end
  end

  it "generates .kamal/secrets" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, ".kamal/secrets"))
    end
  end

  it "secrets has KAMAL_REGISTRY_PASSWORD placeholder" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".kamal/secrets"))
      expect(content).to include("KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD")
    end
  end

  it "secrets has RAILS_MASTER_KEY placeholder" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".kamal/secrets"))
      expect(content).to include("RAILS_MASTER_KEY=$RAILS_MASTER_KEY")
    end
  end

  it "secrets has DATABASE_URL placeholder" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".kamal/secrets"))
      expect(content).to include("DATABASE_URL=$DATABASE_URL")
    end
  end

  it "secrets has POSTGRES_PASSWORD placeholder" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".kamal/secrets"))
      expect(content).to include("POSTGRES_PASSWORD=$POSTGRES_PASSWORD")
    end
  end

  it "secrets does not include VAPID keys without push" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".kamal/secrets"))
      expect(content).not_to include("VAPID_PUBLIC_KEY")
      expect(content).not_to include("VAPID_PRIVATE_KEY")
    end
  end

  it "secrets includes VAPID keys when push is enabled" do
    with_tmp_dir do |tmp|
      run_gen(tmp, "push" => true)
      content = File.read(File.join(tmp, ".kamal/secrets"))
      expect(content).to include("VAPID_PUBLIC_KEY=$VAPID_PUBLIC_KEY")
      expect(content).to include("VAPID_PRIVATE_KEY=$VAPID_PRIVATE_KEY")
    end
  end

  it "secrets contains only ENV placeholders and no real secret values" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, ".kamal/secrets"))
      # Every KEY= line should reference $VAR, not a literal value
      key_lines = content.lines.grep(/^\s*[A-Z_]+=/)
      key_lines.each do |line|
        key = line.split("=").first.strip
        value = line.split("=", 2).last.strip
        expect(value).to start_with("$"), "expected #{key} value to be an ENV placeholder"
      end
    end
  end

  it "generates config/accessories/postgres.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      expect(File).to exist(File.join(tmp, "config/accessories/postgres.yml"))
    end
  end

  it "postgres accessory has postgres:18 image" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/accessories/postgres.yml"))
      expect(content).to include("image: postgres:18")
    end
  end

  it "postgres accessory has port mapping" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/accessories/postgres.yml"))
      expect(content).to include("127.0.0.1:5432:5432")
    end
  end

  it "postgres accessory has data volume" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/accessories/postgres.yml"))
      expect(content).to include("postgres-data:/var/lib/postgresql/data")
    end
  end

  it "postgres accessory has POSTGRES_PASSWORD secret" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/accessories/postgres.yml"))
      expect(content).to include("POSTGRES_PASSWORD")
    end
  end

  it "adds .kamal/secrets to .gitignore" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      gitignore = File.read(File.join(tmp, ".gitignore"))
      expect(gitignore).to include(".kamal/secrets")
    end
  end

  it "is idempotent for kamal gem" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan(/^\s*gem\s+["']kamal["']/m).length).to eq(1)
    end
  end

  it "is idempotent for deploy.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/deploy.yml"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/deploy.yml"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for Dockerfile.prod" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "Dockerfile.prod"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "Dockerfile.prod"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for .kamal/secrets" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, ".kamal/secrets"))
      run_gen(tmp)
      second = File.read(File.join(tmp, ".kamal/secrets"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for postgres accessory" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      first = File.read(File.join(tmp, "config/accessories/postgres.yml"))
      run_gen(tmp)
      second = File.read(File.join(tmp, "config/accessories/postgres.yml"))
      expect(first).to eq(second)
    end
  end

  it "is idempotent for .gitignore" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      run_gen(tmp)
      gitignore = File.read(File.join(tmp, ".gitignore"))
      expect(gitignore.scan(".kamal/secrets").length).to eq(1)
    end
  end

  it "push_enabled? returns false by default" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      expect(gen.push_enabled?).to be(false)
    end
  end

  it "push_enabled? returns true when push option is set" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], { "push" => true }, destination_root: tmp)
      expect(gen.push_enabled?).to be(true)
    end
  end

  it "kamal_app_name defaults to app_name" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      expect(gen.kamal_app_name).to eq(File.basename(tmp))
    end
  end

  it "kamal_image defaults to kamal_app_name" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      expect(gen.kamal_image).to eq(gen.kamal_app_name)
    end
  end

  it "kamal_registry defaults to empty string" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      expect(gen.kamal_registry).to eq("")
    end
  end

  it "kamal_servers defaults to empty string" do
    with_tmp_dir do |tmp|
      gen = described_class.new([], {}, destination_root: tmp)
      expect(gen.kamal_servers).to eq("")
    end
  end

  it "does not hardcode registry host" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      # Should not contain a hardcoded docker.io or ghcr.io registry
      expect(content).not_to include("docker.io")
      expect(content).not_to include("ghcr.io")
    end
  end

  it "does not commit real secrets in deploy.yml" do
    with_tmp_dir do |tmp|
      run_gen(tmp)
      content = File.read(File.join(tmp, "config/deploy.yml"))
      # Only secret references, no literal passwords
      expect(content).not_to match(/password:\s*["']?[a-zA-Z0-9]{8,}/i)
    end
  end
end
