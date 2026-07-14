# frozen_string_literal: true

require "rails/generators"
require "fileutils"

module GeneratorHelper
  def destination_root
    @destination_root ||= File.join(Dir.tmpdir, "generator_spec", SecureRandom.hex(8))
  end

  def prepare_destination
    FileUtils.rm_rf(destination_root)
    FileUtils.mkdir_p(destination_root)
  end

  def run_generator(generator_class, args = [])
    prepare_destination
    generator = generator_class.new(args, destination_root: destination_root)
    generator.invoke_all
  end

  def have_file(path)
    RSpec::Matchers::BuiltIn::Include.new(path).tap do |matcher|
      matcher.define_singleton_method(:matches?) do |_actual|
        file_path = File.join(destination_root, path)
        File.exist?(file_path)
      end

      matcher.define_singleton_method(:failure_message) do
        "expected file #{path} to exist in #{destination_root}"
      end

      matcher.define_singleton_method(:failure_message_when_negated) do
        "expected file #{path} not to exist in #{destination_root}"
      end
    end
  end

  def file_content(path)
    file_path = File.join(destination_root, path)
    File.read(file_path) if File.exist?(file_path)
  end
end

RSpec.configure do |config|
  config.include GeneratorHelper
end
