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
