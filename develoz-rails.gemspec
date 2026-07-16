# frozen_string_literal: true

require_relative "lib/develoz/version"

Gem::Specification.new do |spec|
  spec.name = "develoz-rails"
  spec.version = Develoz::VERSION
  spec.authors = ["Mauricio Zaffari"]
  spec.email = ["mauriciozaffari@gmail.com"]

  spec.summary = "Generate Rails 8.1 applications with Develoz conventions."
  spec.description = "Develoz Rails provides a CLI and composable generators for creating Rails 8.1 applications " \
                     "with a tested core stack and opt-in API, authentication, UI, deployment, and operations features."
  spec.homepage = "https://github.com/develoz-com/rails-template"
  spec.required_ruby_version = ">= 3.4"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/v#{spec.version}"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", "~> 8.1"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tty-prompt", "~> 0.23"

  spec.add_development_dependency "aruba", "~> 2.2"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.65"
  spec.add_development_dependency "rubocop-performance", "~> 1.21"
  spec.add_development_dependency "rubocop-rails", "~> 2.25"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-lcov", "~> 0.8"
  spec.add_development_dependency "webmock", "~> 3.23"
end
