# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-07-15

### Added

- Initial `develoz` CLI with interactive and `--yes` application generation.
- Ruby and Rails version resolution for new Rails 8.1 applications.
- Core generators for tooling, testing, the Solid stack, CI, PostgreSQL,
  shared concerns, strict loading, maintenance tasks, frontend conventions,
  documentation, and application versioning.
- Opt-in generators for APIs, authentication, PWA support, push
  notifications, Active Resource, admin interfaces, Develoz UI, Kamal,
  Docker, and database backups.
- Pagy pagination by default with a `--skip-pagy` opt-out.
- Canonical fixture fidelity tests and a full RSpec, coverage, and RuboCop CI
  workflow.

[Unreleased]: https://github.com/develoz/develoz-rails/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/develoz/develoz-rails/releases/tag/v0.1.0
