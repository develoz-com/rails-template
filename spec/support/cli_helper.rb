# frozen_string_literal: true

require "open3"
require "pathname"
require "fileutils"

module CLIHelper
  GenerateAppResult = Struct.new(:dir, :status, :out, :err)

  def generate_app(flags = [])
    tmp_app_dir = File.join(Dir.tmpdir, "develoz_app_#{SecureRandom.hex(8)}")
    exe_path = File.expand_path("../../exe/develoz", __dir__)

    cmd = [exe_path, "new", tmp_app_dir] + flags
    stdout, stderr, status = Open3.capture3(*cmd)

    GenerateAppResult.new(
      Pathname.new(tmp_app_dir),
      status.exitstatus,
      stdout,
      stderr
    )
  end
end

RSpec.configure do |config|
  config.include CLIHelper
end
