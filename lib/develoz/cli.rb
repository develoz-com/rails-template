# frozen_string_literal: true

require "thor"

module Develoz
  class CLI < Thor
    desc "version", "Show version"
    def version
      puts "develoz #{Develoz::VERSION}"
    end
  end
end
