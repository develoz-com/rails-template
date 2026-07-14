# frozen_string_literal: true

module Develoz
  class Error < StandardError; end
end

require_relative "develoz/version"

Dir[File.expand_path("develoz/**/*.rb", __dir__)].each do |file|
  require file unless file.end_with?("version.rb")
end
