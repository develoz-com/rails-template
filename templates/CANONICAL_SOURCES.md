# Canonical Sources

This document maps generator tasks to their canonical source files in external repositories. Each entry describes where a file is fetched from, where it is stored as a fixture, and how it is used in template generation.

## Canonical File Mapping

| Generator/Task | Source Repo | Source Path | Fixture Path | Template Destination | Substitutions |
|---|---|---|---|---|---|
| pull_request_template (T6 demo) | develoz-com/inscripto-v2 | `.github/pull_request_template.md` | `spec/fixtures/canonical/develoz-com-inscripto-v2/.github/pull_request_template.md` | `templates/pull_request_template.md.tt` | verbatim |
| concerns (T10) | develoz-com/looper_core | `app/concerns/...` | `spec/fixtures/canonical/develoz-com-looper_core/...` | `templates/concerns/...tt` | app_name, app_class |
| ci (T11) | develoz-com/ams2stats | `bin/ci`, `config/ci.rb` | `spec/fixtures/canonical/develoz-com-ams2stats/...` | `templates/bin/ci.tt`, `templates/config/ci.rb.tt` | app_name, app_class |
| solid (T12) | mauriciozaffari/ams2stats | `config/queue.yml`, `config/cache.yml`, `config/cable.yml`, `config/recurring.yml`, `config/initializers/mission_control.rb`, `app/jobs/application_job.rb` | `spec/fixtures/canonical/mauriciozaffari-ams2stats/...` | `templates/config/queue.yml.tt`, `templates/config/cache.yml.tt`, `templates/config/cable.yml.tt`, `templates/config/recurring.yml.tt`, `templates/config/initializers/mission_control.rb.tt`, `templates/app/jobs/application_job.rb.tt` | adapted (sqlite→postgres), ENV vars |
| pwa (T13) | develoz-com/inscripto-v2 | `app/views/pwa/...` | `spec/fixtures/canonical/develoz-com-inscripto-v2/...` | `templates/pwa/...tt` | app_name, app_class |
| push (T14) | develoz-com/inscripto-v2 | `app/models/push/...` | `spec/fixtures/canonical/develoz-com-inscripto-v2/...` | `templates/push/...tt` | app_name, app_class |
| kamal (T15) | develoz-com/inscripto-v2 | `config/deploy.yml` | `spec/fixtures/canonical/develoz-com-inscripto-v2/...` | `templates/config/deploy.yml.tt` | app_name, ENV vars |
| admin (T16) | develoz-com/inscripto-v2 | `app/admin/...` | `spec/fixtures/canonical/develoz-com-inscripto-v2/...` | `templates/admin/...tt` | app_name, app_class |
| develoz_ui (T17) | develoz-com/inscripto-v2 | `app/components/develoz_ui/...` | `spec/fixtures/canonical/develoz-com-inscripto-v2/...` | `templates/develoz_ui/...tt` | app_name, app_class |
| bin/run (T18) | develoz-com/agent | `bin/run` | `spec/fixtures/canonical/develoz-com-agent/bin/run` | `templates/bin/run.tt` | verbatim |
| ci (T13) | mauriciozaffari/ams2stats | `bin/ci`, `config/ci.rb` | — | `templates/bin/ci.tt`, `templates/config/ci.rb.tt` | adapted, extended linter set |
| ci (T13) | LooperInsights/looper_core | `.rubocop.yml`, `.reek.yml`, `biome.json`, `.stylelintrc.json`, `.haml-lint.yml`, `.markdownlint.yaml`, `.yamllint` | — | `templates/.rubocop.yml.tt`, `templates/.reek.yml.tt`, `templates/biome.json.tt`, `templates/.stylelintrc.json.tt`, `templates/.haml-lint.yml.tt`, `templates/.markdownlint.json.tt`, `templates/.yamllint.tt` | adapted, simplified for new Rails apps |
| ci (T13) | — | — | — | `templates/.github/workflows/ci.yml.tt` | authored (simple CI runner) |
| concerns (T15) | LooperInsights/looper_core | `app/models/concerns/searchable_concern.rb`, `app/models/concerns/optimized_finders.rb`, `app/models/concerns/transitionable.rb`, `app/models/concerns/configurable.rb` | `spec/fixtures/canonical/LooperInsights-looper_core/app/models/concerns/...` | `templates/app/models/concerns/...tt` | verbatim |
| concerns (T15) | LooperInsights/looper_core | `db/migrate/20260506120000_add_status_columns_to_merchandizing_pages.rb`, `db/migrate/20250524195130_create_configurations.rb` | — | `templates/db/migrate/add_status_transitions.rb.tt`, `templates/db/migrate/create_configurations.rb.tt` | adapted (generic table names) |
| concerns (T15) | — | — | — | `templates/spec/models/concerns/...tt` | authored (modeled on looper_core specs) |
| docs_render (T19) | LooperInsights/looper_core | `app/models/document.rb`, `app/javascript/docs.js`, `app/assets/stylesheets/documentation.scss` | `spec/fixtures/canonical/LooperInsights-looper_core/app/models/document.rb`, `.../app/javascript/docs.js`, `.../app/assets/stylesheets/documentation.scss` | `templates/app/models/document.rb.tt`, `templates/app/javascript/docs.js.tt`, `templates/app/assets/stylesheets/documentation.scss.tt` | verbatim |
| docs_render (T19) | LooperInsights/looper_core | `app/controllers/docs_controller.rb` | — | `templates/app/controllers/docs_controller.rb.tt` | adapted (AdminController -> ApplicationController) |
| docs_render (T19) | LooperInsights/looper_core | `app/views/docs/show.html.haml` | — | `templates/app/views/docs/show.html.erb.tt` | adapted (HAML -> ERB, inner ERB escaped with `<%%= %>`) |
| docs_render (T19) | — | — | — | `templates/config/initializers/redcarpet_rouge.rb.tt` | authored (looper_core has no separate initializer; Document model handles config inline) |
| doc_specs (T20) | LooperInsights/looper_core | `bin/generate-docs` | `spec/fixtures/canonical/LooperInsights-looper_core/bin/generate-docs` | `templates/bin/generate-docs.tt` | verbatim |
| doc_specs (T20) | LooperInsights/looper_core | `spec/rails_helper.rb` (inline module) | — | `templates/spec/support/doc_screenshot_helper.rb.tt` | authored (extracted from rails_helper.rb inline module into standalone support file) |
| doc_specs (T20) | LooperInsights/looper_core | `Rakefile` (inline task) | — | `templates/lib/tasks/docs_check.rake.tt` | adapted (extracted docs:check namespace from Rakefile into standalone rake file) |
| doc_specs (T20) | — | — | — | `templates/spec/system/example_doc_spec.rb.tt` | authored (demonstrates @category, @order, doc_screenshot pattern) |
| agents_docs (T21) | develoz-com/agent | `AGENTS.md` | — | `lib/generators/develoz/agents_docs/templates/AGENTS.md.tt` | adapted (generic for any develoz app; removed bin/run, develoz_agent CLI, agent-specific docs) |
| agents_docs (T21) | develoz-com/agent | `docs/development.md` | — | `lib/generators/develoz/agents_docs/templates/docs/development.md.tt` | adapted (removed bin/run, develoz_agent CLI, agent-specific sections) |
| agents_docs (T21) | develoz-com/agent | `docs/testing.md` | — | `lib/generators/develoz/agents_docs/templates/docs/testing.md.tt` | adapted (removed bin/run, agent-specific external tool stubs) |
| agents_docs (T21) | develoz-com/agent | `docs/performance.md` | — | `lib/generators/develoz/agents_docs/templates/docs/performance.md.tt` | adapted (removed agent-specific query paths, indexes, Jira caching) |
| agents_docs (T21) | develoz-com/inscripto-v2 | `.github/pull_request_template.md` | `spec/fixtures/canonical/develoz-com-inscripto-v2/.github/pull_request_template.md` | `lib/generators/develoz/agents_docs/templates/.github/pull_request_template.md.tt` | verbatim |
| agents_docs (T21) | — | — | — | `lib/generators/develoz/agents_docs/templates/spec/support/vcr.rb.tt` | authored (VCR config with WebMock) |
| agents_docs (T21) | — | — | — | `lib/generators/develoz/agents_docs/templates/spec/support/faraday.rb.tt` | authored (Faraday factory with retry middleware) |
| agents_docs (T21) | — | — | — | `lib/generators/develoz/agents_docs/templates/spec/requests/example_api_spec.rb.tt` | authored (demonstrates VCR + Faraday pattern) |
| agents_docs (T21) | — | — | — | `lib/generators/develoz/agents_docs/templates/spec/cassettes/Example_API/fetches_data_from_an_external_API.yml.tt` | authored (stub VCR cassette fixture) |
| versioning (T36) | develoz-com/inscripto-v2 | `app/helpers/application_helper.rb` (app_version method) | `spec/fixtures/canonical/develoz-com-inscripto-v2/app/helpers/app_version.rb` | `lib/generators/develoz/versioning/templates/app/helpers/application_helper.rb.tt` | verbatim (method snippet) |
| versioning (T36) | develoz-com/inscripto-v2 | `config/constants.rb` (APP_VERSION line) | — | `lib/generators/develoz/versioning/versioning_generator.rb` (inject_once) | adapted (injected into constants.rb after marker) |
| versioning (T36) | — | — | — | `lib/generators/develoz/versioning/templates/app/views/shared/_app_version.html.erb.tt` | authored (extracted from inscripto's inline sidebar version display into reusable partial) |

## Pipeline Workflow

For each canonical file:

1. **Fetch**: Use `Develoz::CanonicalFetcher.fetch(repo:, path:, dest:)` to download the raw file from GitHub and save it to `spec/fixtures/canonical/<repo-owner-repo>/<path>`.
2. **Fixture**: Commit the fixture file to the repo (byte-identical to source).
3. **Template**: Create a `.tt` ERB template in `templates/` that copies the fixture content, applying substitutions (app_name, app_class, ENV vars) as needed.
4. **Fidelity Test**: Write a spec in `spec/fidelity/<name>_fidelity_spec.rb` that renders the template and compares it to the fixture using the `match_canonical` matcher.

## Substitution Variables

- **app_name**: Lowercase app name (e.g., "my_app")
- **app_class**: CamelCase app name (e.g., "MyApp")
- **ENV vars**: Environment-specific values (e.g., `<%= ENV["APP_VERSION"] %>`)
- **verbatim**: No substitution; file is copied as-is

## Running the Fetcher

To fetch all canonical files:

```bash
bundle exec rake develoz:fetch_canonical
```

To fetch a single file, call the fetcher directly:

```ruby
Develoz::CanonicalFetcher.fetch(
  repo: "develoz-com/inscripto-v2",
  path: ".github/pull_request_template.md",
  dest: "spec/fixtures/canonical/develoz-com-inscripto-v2/.github/pull_request_template.md"
)
```

## Notes

- All fixtures are committed to the repo and must be byte-identical to their source.
- Templates are ERB files that render fixtures with substitutions.
- Fidelity tests verify that rendered templates match their fixtures.
- Private repos (looper_core, inscripto-v2, agent) require GitHub authentication via `GH_TOKEN` or `gh auth token`.
