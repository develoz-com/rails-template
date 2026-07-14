# frozen_string_literal: true

require_relative "../../spec_helper"
require "develoz/generators/base"
require "fileutils"
require "tmpdir"

RSpec.describe Develoz::Generators::Base do
  let(:real_gemfile_path) { File.expand_path("Gemfile", Dir.pwd) }
  let(:real_gemfile) { File.read(real_gemfile_path) if File.exist?(real_gemfile_path) }
  let(:tmp_dir) { Dir.mktmpdir }

  after do
    # Safety guard: verify the real Gemfile is unchanged
    if real_gemfile && File.exist?(real_gemfile_path)
      current_gemfile = File.read(real_gemfile_path)
      raise "Real Gemfile was modified by test!" unless current_gemfile == real_gemfile
    end

    FileUtils.rm_rf(tmp_dir) if tmp_dir && File.exist?(tmp_dir)
  end

  def create_fixture_file(path, content = "")
    full_path = File.join(tmp_dir, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe ".source_root" do
    it "returns the templates directory" do
      expect(described_class.source_root).to include("templates")
      expect(File.directory?(described_class.source_root)).to be true
    end
  end

  describe "#app_name" do
    it "returns the basename of destination_root" do
      gen = described_class.new([], {}, destination_root: tmp_dir)
      expect(gen.destination_root).to eq(tmp_dir)
      expect(gen.app_name).to eq(File.basename(tmp_dir))
    end
  end

  describe "#app_class" do
    it "returns the camelized app_name" do
      test_dir = File.join(tmp_dir, "my_app")
      FileUtils.mkdir_p(test_dir)
      gen = described_class.new([], {}, destination_root: test_dir)
      expect(gen.app_class).to eq("MyApp")
    end
  end

  describe "#inject_once" do
    context "when marker is present" do
      it "skips injection (idempotency)" do
        create_fixture_file("test.rb", "# marker: setup\nnew line\noriginal content\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.inject_once(
          into: "test.rb",
          content: "new line",
          after: "# marker: setup",
          marker: "new line"
        )

        content = File.read(File.join(tmp_dir, "test.rb"))
        expect(content).to eq("# marker: setup\nnew line\noriginal content\n")
      end
    end

    context "when content is already present" do
      it "skips injection (idempotency)" do
        create_fixture_file("test.rb", "# setup\nexisting content\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.inject_once(
          into: "test.rb",
          content: "existing content",
          after: "# setup"
        )

        content = File.read(File.join(tmp_dir, "test.rb"))
        expect(content).to eq("# setup\nexisting content\n")
      end
    end

    context "when file does not exist" do
      it "does nothing" do
        gen = described_class.new([], {}, destination_root: tmp_dir)
        gen.inject_once(
          into: "nonexistent.rb",
          content: "new line",
          after: "# marker"
        )

        expect(File.exist?(File.join(tmp_dir, "nonexistent.rb"))).to be false
      end
    end

    context "when injecting after a marker" do
      it "injects content after the marker" do
        create_fixture_file("test.rb", "# setup\noriginal\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.inject_once(
          into: "test.rb",
          content: "injected line",
          after: "# setup"
        )

        content = File.read(File.join(tmp_dir, "test.rb"))
        expect(content).to include("injected line")
      end
    end

    context "when injecting before a marker" do
      it "injects content before the marker" do
        create_fixture_file("test.rb", "original\n# end\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.inject_once(
          into: "test.rb",
          content: "injected line",
          before: "# end"
        )

        content = File.read(File.join(tmp_dir, "test.rb"))
        expect(content).to include("injected line")
      end
    end

    context "when neither after nor before is specified" do
      it "injects content at the end" do
        create_fixture_file("test.rb", "original\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.inject_once(
          into: "test.rb",
          content: "appended line"
        )

        content = File.read(File.join(tmp_dir, "test.rb"))
        expect(content).to include("appended line")
      end
    end

    context "when running twice" do
      it "produces the same result on second run" do
        create_fixture_file("test.rb", "# setup\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.inject_once(into: "test.rb", content: "line1", after: "# setup", marker: "line1")
        first_content = File.read(File.join(tmp_dir, "test.rb"))

        gen.inject_once(into: "test.rb", content: "line1", after: "# setup", marker: "line1")
        second_content = File.read(File.join(tmp_dir, "test.rb"))

        expect(second_content).to eq(first_content)
      end
    end
  end

  describe "#add_gem" do
    context "when gem is not present" do
      it "adds the gem to Gemfile" do
        create_fixture_file("Gemfile", "source \"https://rubygems.org\"\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.add_gem("rails", "~> 8.0")

        content = File.read(File.join(tmp_dir, "Gemfile"))
        expect(content).to include("rails")
      end
    end

    context "when gem is already present" do
      it "skips adding (idempotency)" do
        create_fixture_file("Gemfile", "gem \"rails\", \"~> 8.0\"\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.add_gem("rails", "~> 8.1")

        content = File.read(File.join(tmp_dir, "Gemfile"))
        expect(content).to include("~> 8.0")
        expect(content).not_to include("~> 8.1")
      end
    end

    context "when Gemfile does not exist" do
      it "does nothing" do
        gen = described_class.new([], {}, destination_root: tmp_dir)
        gen.add_gem("rails")

        expect(File.exist?(File.join(tmp_dir, "Gemfile"))).to be false
      end
    end

    context "with group option" do
      it "adds gem with group" do
        create_fixture_file("Gemfile", "source \"https://rubygems.org\"\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.add_gem("rspec", "~> 3.0", group: :development)

        content = File.read(File.join(tmp_dir, "Gemfile"))
        expect(content).to include("rspec")
      end
    end

    context "with version only" do
      it "adds gem with version" do
        create_fixture_file("Gemfile", "source \"https://rubygems.org\"\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.add_gem("rails", "~> 8.0")

        content = File.read(File.join(tmp_dir, "Gemfile"))
        expect(content).to include("rails")
      end
    end

    context "with additional options" do
      it "adds gem with options" do
        create_fixture_file("Gemfile", "source \"https://rubygems.org\"\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.add_gem("devise", "~> 4.9", require: false)

        content = File.read(File.join(tmp_dir, "Gemfile"))
        expect(content).to include("devise")
      end
    end

    context "when running twice" do
      it "produces the same result on second run" do
        create_fixture_file("Gemfile", "source \"https://rubygems.org\"\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.add_gem("rails", "~> 8.0")
        first_content = File.read(File.join(tmp_dir, "Gemfile"))

        gen.add_gem("rails", "~> 8.0")
        second_content = File.read(File.join(tmp_dir, "Gemfile"))

        expect(second_content).to eq(first_content)
      end
    end
  end

  describe "#insert_route" do
    context "when route is not present" do
      it "inserts the route into config/routes.rb" do
        create_fixture_file("config/routes.rb", "Rails.application.routes.draw do\nend\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.insert_route("resources :posts")

        content = File.read(File.join(tmp_dir, "config/routes.rb"))
        expect(content).to include("resources :posts")
      end
    end

    context "when route is already present" do
      it "skips insertion (idempotency)" do
        create_fixture_file("config/routes.rb", "Rails.application.routes.draw do\n  resources :posts\nend\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.insert_route("resources :posts")

        content = File.read(File.join(tmp_dir, "config/routes.rb"))
        expect(content.scan("resources :posts").length).to eq(1)
      end
    end

    context "when routes.rb does not exist" do
      it "does nothing" do
        gen = described_class.new([], {}, destination_root: tmp_dir)
        gen.insert_route("resources :posts")

        expect(File.exist?(File.join(tmp_dir, "config/routes.rb"))).to be false
      end
    end

    context "when running twice" do
      it "produces the same result on second run" do
        create_fixture_file("config/routes.rb", "Rails.application.routes.draw do\nend\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.insert_route("resources :posts")
        first_content = File.read(File.join(tmp_dir, "config/routes.rb"))

        gen.insert_route("resources :posts")
        second_content = File.read(File.join(tmp_dir, "config/routes.rb"))

        expect(second_content).to eq(first_content)
      end
    end
  end

  describe "#append_env" do
    context "when key is not present in .env" do
      it "appends key=value to .env" do
        create_fixture_file(".env", "EXISTING=value\n")
        create_fixture_file(".env.example", "EXISTING=\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.append_env("NEW_KEY", "new_value")

        env_content = File.read(File.join(tmp_dir, ".env"))
        expect(env_content).to include("NEW_KEY=new_value")
      end
    end

    context "when key is already present in .env" do
      it "skips appending (idempotency)" do
        create_fixture_file(".env", "KEY=value\n")
        create_fixture_file(".env.example", "KEY=\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.append_env("KEY", "new_value")

        env_content = File.read(File.join(tmp_dir, ".env"))
        expect(env_content).to eq("KEY=value\n")
      end
    end

    context "when .env does not exist" do
      it "does nothing" do
        gen = described_class.new([], {}, destination_root: tmp_dir)
        gen.append_env("KEY", "value")

        expect(File.exist?(File.join(tmp_dir, ".env"))).to be false
      end
    end

    context "when example: false" do
      it "does not append to .env.example" do
        create_fixture_file(".env", "KEY=value\n")
        create_fixture_file(".env.example", "")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.append_env("NEW_KEY", "value", example: false)

        example_content = File.read(File.join(tmp_dir, ".env.example"))
        expect(example_content).not_to include("NEW_KEY")
      end
    end

    context "when running twice" do
      it "produces the same result on second run" do
        create_fixture_file(".env", "")
        create_fixture_file(".env.example", "")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.append_env("KEY", "value")
        first_content = File.read(File.join(tmp_dir, ".env"))

        gen.append_env("KEY", "value")
        second_content = File.read(File.join(tmp_dir, ".env"))

        expect(second_content).to eq(first_content)
      end
    end
  end

  describe "#ensure_gitignore" do
    context "when pattern is not present" do
      it "appends pattern to .gitignore" do
        create_fixture_file(".gitignore", "*.log\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.ensure_gitignore("*.tmp")

        content = File.read(File.join(tmp_dir, ".gitignore"))
        expect(content).to include("*.tmp")
      end
    end

    context "when pattern is already present" do
      it "skips appending (idempotency)" do
        create_fixture_file(".gitignore", "*.log\n")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.ensure_gitignore("*.log")

        content = File.read(File.join(tmp_dir, ".gitignore"))
        expect(content.scan("*.log").length).to eq(1)
      end
    end

    context "when .gitignore does not exist" do
      it "does nothing" do
        gen = described_class.new([], {}, destination_root: tmp_dir)
        gen.ensure_gitignore("*.log")

        expect(File.exist?(File.join(tmp_dir, ".gitignore"))).to be false
      end
    end

    context "when running twice" do
      it "produces the same result on second run" do
        create_fixture_file(".gitignore", "")
        gen = described_class.new([], {}, destination_root: tmp_dir)

        gen.ensure_gitignore("*.log")
        first_content = File.read(File.join(tmp_dir, ".gitignore"))

        gen.ensure_gitignore("*.log")
        second_content = File.read(File.join(tmp_dir, ".gitignore"))

        expect(second_content).to eq(first_content)
      end
    end
  end

  describe "#apply_template" do
    context "when template exists" do
      it "copies template to destination" do
        # Create a template in the source_root
        template_dir = File.join(described_class.source_root)
        FileUtils.mkdir_p(template_dir)
        template_file = File.join(template_dir, "test_template.txt")
        File.write(template_file, "template content\n")

        gen = described_class.new([], {}, destination_root: tmp_dir)
        gen.apply_template("test_template.txt", "output.txt")

        expect(File.exist?(File.join(tmp_dir, "output.txt"))).to be true
        expect(File.read(File.join(tmp_dir, "output.txt"))).to eq("template content\n")

        # Cleanup
        File.delete(template_file)
      end
    end

    context "when template does not exist" do
      it "does nothing" do
        gen = described_class.new([], {}, destination_root: tmp_dir)
        gen.apply_template("nonexistent.txt", "output.txt")

        expect(File.exist?(File.join(tmp_dir, "output.txt"))).to be false
      end
    end
  end

  describe "destination_root binding" do
    it "respects the destination_root passed to the constructor" do
      gen = described_class.new([], {}, destination_root: tmp_dir)
      expect(gen.destination_root).to eq(tmp_dir)
    end

    it "does not default to Dir.pwd" do
      gen = described_class.new([], {}, destination_root: tmp_dir)
      expect(gen.destination_root).not_to eq(Dir.pwd)
    end
  end
end
