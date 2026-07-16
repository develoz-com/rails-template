# Develoz Rails Generator Pattern - Learnings

## Working Generator Pattern (Task 10 - ToolingGenerator)

### Key Success Factors

1. **Source Root Override**: Use `def self.source_root` to override the base class method
   - Pattern: `File.expand_path("templates", __dir__)`
   - This avoids the Thor `source_paths` error that caused infinite loops in prior attempts
   - Templates must be co-located in `lib/generators/develoz/<generator_name>/templates/`

2. **Per-File Templates**: Use `template` method for each file, NOT Thor's `directory` method
   - `template "vscode/settings.json.tt", ".vscode/settings.json"`
   - `template "env.example.tt", ".env.example"`
   - This gives fine-grained control and avoids directory-level issues

3. **Destination Root Binding in Specs**: CRITICAL for test isolation
   - Always pass `destination_root: tmp_dir` when instantiating the generator
   - Assert `expect(gen.destination_root).to eq(tmp_dir)` to verify binding
   - Without this, the generator writes to the real repo and corrupts it

4. **Calling Generator Methods**: Do NOT use `invoke_all` in tests
   - Reason: Thor treats all public methods as tasks, including helper methods like `inject_once`
   - Instead: Call specific methods directly: `gen.create_vscode; gen.create_env_files; ...`
   - This avoids calling base class helper methods as tasks

5. **Template Content**: Use ERB syntax for dynamic values
   - `<%= app_name %>` works because base class defines `app_name` method
   - Templates are processed through Rails' template engine

6. **Idempotency**: Use base class helpers with built-in guards
   - `add_gem` checks if gem already exists before adding
   - `ensure_gitignore` checks if pattern already exists
   - `create_file` with conditional check for `.env`
   - These prevent duplicate entries on re-runs

### File Structure

```
lib/generators/develoz/tooling/
├── tooling_generator.rb
└── templates/
    ├── vscode/
    │   ├── settings.json.tt
    │   ├── extensions.json.tt
    │   └── tasks.json.tt
    ├── env.example.tt
    └── constants.rb.tt

spec/develoz/generators/
└── tooling_generator_spec.rb
```

### Generator Methods Pattern

```ruby
class ToolingGenerator < Develoz::Generators::Base
  def self.source_root
    File.expand_path("templates", __dir__)
  end

  def create_vscode
    template "vscode/settings.json.tt", ".vscode/settings.json"
    # ... more templates
  end

  def create_env_files
    template "env.example.tt", ".env.example"
    create_file ".env", "" unless File.exist?(File.join(destination_root, ".env"))
    ensure_gitignore(".env")
  end

  def add_dotenv
    add_gem "dotenv-rails", group: %i[development test]
  end
end
```

### Spec Pattern

- Use `with_tmp_dir` helper to create isolated temp directories
- Seed minimal Gemfile and .gitignore for base class helpers to work
- Call generator methods directly, not `invoke_all`
- Keep expectations to 3 per test (RuboCop rule)
- Avoid instance variables; use local variables and method parameters

### Coverage Requirements

- Generator code: 100% line + branch coverage
- Full suite: 100% line + branch coverage (includes all lib files)
- Tests must reach all branches (e.g., both `.env` exists/not-exists paths)

## Reuse for T11-T31

This pattern is stable and should be reused for all subsequent generators:
1. Create generator in `lib/generators/develoz/<name>/<name>_generator.rb`
2. Create templates in `lib/generators/develoz/<name>/templates/`
3. Override `source_root` with `File.expand_path("templates", __dir__)`
4. Use per-file `template` calls
5. Create spec in `spec/develoz/generators/<name>_generator_spec.rb`
6. Bind `destination_root` in all spec instantiations
7. Call methods directly, not `invoke_all`
8. Ensure 100% coverage with focused tests (max 3 expectations each)

## SimpleCov + Parallel Test Collation (Task 11 - TestingGenerator)

The generated app's test setup uses SimpleCov with parallel_tests collation:

1. **SimpleCov Configuration** (spec/spec_helper.rb):
   - `enable_coverage :branch` for branch coverage tracking
   - `minimum_coverage line: 100, branch: 100` enforces 100% coverage
   - `coverage_dir "public/coverage"` outputs to public/coverage (not repo root)
   - `SimpleCov.command_name "RSpec_#{ENV['TEST_ENV_NUMBER']}"` tags each parallel process
   - `SimpleCov.use_merging true` merges coverage across parallel processes
   - `add_filter %w[/spec/ /config/ /db/]` excludes test/config/db files from coverage

2. **Parallel Test Collation**:
   - When running `parallel_tests`, each process gets a unique `TEST_ENV_NUMBER`
   - SimpleCov uses this to create separate coverage reports per process
   - The `use_merging true` flag combines all reports into a single result
   - This allows 100% coverage enforcement even with parallel test execution

3. **Capybara + Selenium Configuration** (spec/rails_helper.rb):
   - Registers `:headless_chrome` driver with Selenium WebDriver
   - Chrome options: `--headless=new`, `--no-sandbox`, `--disable-gpu`
   - Sets `Capybara.javascript_driver = :headless_chrome` for JS tests
   - FactoryBot configured to load factories from `spec/factories`
   - `ActiveRecord::Migration.maintain_test_schema!` keeps test DB in sync

4. **RSpec Configuration**:
   - `.rspec` and `.rspec_parallel` both use `--require spec_helper --format documentation`
   - `spec/spec_helper.rb` loaded first (SimpleCov setup)
   - `spec/rails_helper.rb` requires spec_helper, then adds Rails-specific config
   - Support files auto-loaded from `spec/support/**/*.rb`

This approach is used by T20 (database setup) and T32 (CI/parallel execution).

## Solid Queue/Cache/Cable Stack (Task 12 - SolidGenerator)

The solid generator adds Solid Queue, Solid Cache, Solid Cable, and Mission Control Jobs to a Rails app.

### Canonical Sources

The generator sources configuration files from the ams2stats repo:
- **Verbatim files**: `config/queue.yml`, `config/cache.yml`, `config/recurring.yml`, `app/jobs/application_job.rb` are copied directly from ams2stats (SQLite-based).
- **Adapted files**: `config/cable.yml` is adapted from ams2stats (changes Redis URL handling for production). `config/initializers/mission_control.rb` is verbatim.
- **Generated files**: `config/initializers/solid.rb` is authored (sets queue_adapter, cache_store, and cable config).

### Key Differences from ams2stats

ams2stats uses SQLite and runs on Windows without `fork()`. The develoz-rails template targets Postgres with multi-database support (T14 will define named connections `queue`, `cache`, `cable`). The YAML files are structured identically but will reference those named connections in production.

### Generator Methods

1. `add_solid_gems` - adds solid_queue, solid_cache, solid_cable, mission_control-jobs
2. `create_queue_config` - generates config/queue.yml with dispatcher/worker config
3. `create_cache_config` - generates config/cache.yml with store options
4. `create_cable_config` - generates config/cable.yml with async/test/redis adapters
5. `create_recurring_config` - generates config/recurring.yml with cleanup task
6. `create_application_job` - generates app/jobs/application_job.rb base class
7. `create_mission_control_initializer` - generates config/initializers/mission_control.rb with HTTP basic auth
8. `create_solid_initializer` - generates config/initializers/solid.rb with Rails config
9. `insert_mission_control_route` - idempotently mounts MissionControl::Jobs::Engine at /jobs

### Idempotency

All methods use base class helpers (add_gem, insert_route, template) which guard against duplicates:
- `add_gem` checks if gem already exists in Gemfile
- `insert_route` checks if route already exists in routes.rb
- `template` overwrites files (idempotent by nature)

### Spec Coverage

The spec file has 40+ tests covering:
- Gem additions (4 tests)
- Config file generation (queue, cache, cable, recurring)
- Initializer generation (mission_control, solid)
- Route insertion
- Idempotency (run twice, verify single entries)
- Content validation (structure, env vars, frozen_string_literal)

## CI Generator (Task 13)

### Pattern

The ci generator follows the same pattern as tooling/testing/solid generators:
1. Generator class at `lib/generators/develoz/ci/ci_generator.rb`
2. Templates co-located in `lib/generators/develoz/ci/templates/`
3. Spec at `spec/develoz/generators/ci_generator_spec.rb`

### Key Files Generated

- **bin/ci** - CI entry point (`require "active_support/continuous_integration"`, loads `config/ci.rb`)
- **config/ci.rb** - Step definitions using `CI.run do ... end` with setup, style (Ruby/JS/YAML/Markdown), security, and test steps
- **Linter configs**: `.rubocop.yml`, `.reek.yml`, `biome.json`, `.stylelintrc.json`, `.haml-lint.yml`, `.markdownlint.json`, `.yamllint`
- **Workflow**: `.github/workflows/ci.yml` (simple workflow running `bin/ci`)

### Gem Additions

All added to `[:development, :test]` group:
- `rubocop-rails-omakase` (RuboCop with Rails defaults)
- `reek` (code smell detector)
- `flay` (code duplication analysis)
- `brakeman` (security static analysis)
- `bundler-audit` (gem vulnerability check)
- `haml_lint` (Haml template linting, require: false)

### Canonical Sources

Linter configs are adapted from `LooperInsights/looper_core` (RuboCop, Reek, Biome, Stylelint, haml-lint, markdownlint, yamllint). `bin/ci` and `config/ci.rb` are adapted from `mauriciozaffari/ams2stats`. The CI workflow is authored.

### Spec Structure

55+ tests covering:
- 6 gem addition tests (one per gem)
- 7 gem idempotency tests (combined and individual)
- File existence for all 10 generated files
- Content validation for each file (structure, key settings)
- Idempotency for all file types
- 100% line + branch coverage verified

## Database Generator (Task 14)

The database generator adds PostgreSQL and pg_search gems, generates database.yml with Postgres 18+ config, creates a pg_search initializer, and ensures .tool-versions includes postgres 18.

### Key Decisions

1. **database.yml structure**: Uses named connections (primary, queue, cache, cable) for all environments. Production uses DATABASE_URL pattern for the primary connection. Test env uses TEST_ENV_NUMBER suffix for parallel_tests.

2. **pg_search initializer**: Minimal - just a comment noting that PgSearch is included via the searchable concern (T15). No global configuration needed at this stage.

3. **.tool-versions handling**: Uses `inject_once` when the file exists (idempotent append), `create_file` when it doesn't. Both branches tested for 100% coverage.

### Generator Methods

1. `add_database_gems` - adds pg and pg_search gems
2. `create_database_config` - generates config/database.yml with Postgres config
3. `create_pg_search_initializer` - generates config/initializers/pg_search.rb
4. `ensure_postgres_tool_version` - ensures .tool-versions has postgres 18

### Idempotency

- `add_gem` guards against duplicate gem declarations
- `template` overwrites files (idempotent by nature)
- `inject_once` guards against duplicate content in .tool-versions
- `create_file` only called when .tool-versions doesn't exist

### Testing ENV.fetch Patterns

When testing templates that use `ENV.fetch`, the ERB is processed at generation time. To verify the pattern works, set the env var before running the generator and assert the evaluated value appears in the output. Use `begin/ensure` to restore the env var after the test.

## Concerns Generator (Task 15)

The concerns generator copies 4 concern files from `LooperInsights/looper_core` verbatim, plus 2 migrations and 4 app-level spec templates.

### Canonical Sources

- **Verbatim concerns**: `searchable_concern.rb` (PgSearch), `optimized_finders.rb` (in-memory finders), `transitionable.rb` (state machine + JSONB history), `configurable.rb` (polymorphic config + global fallback). None reference an app name, so no ERB substitution is needed — the `.tt` files are byte-identical to the fixtures.
- **Migrations**: `add_status_transitions.rb.tt` is adapted from looper_core's `add_status_columns_to_merchandizing_pages` migration (generic `:records` table name). `create_configurations.rb.tt` is adapted from looper_core's `create_configurations` migration (UUID primary keys with pgcrypto, polymorphic columns, concurrent indexes).
- **App-level specs**: Authored templates modeled on looper_core's own specs. Each spec defines its own test models using `stub_const` and `ActiveRecord::Schema.define` with `before(:all)`/`after(:all)` to create/drop temporary tables. This makes them self-contained and runnable in any generated Rails app.

### Transitionable Schema

The transitionable concern uses a `status` string column (enum) and a `status_transitions` JSONB column (default: `[]`) on the model itself — NOT a separate transitions table. Each entry is `{ "to_state" => "...", "created_at" => "<ISO8601>", "metadata" => {...} }`.

### Configurable Schema

The configurable concern uses a polymorphic `configurations` table with UUID primary keys, `configurable_type`/`configurable_id` columns, `key`/`value` (jsonb), and `active` boolean. Global configurations have `configurable_type` and `configurable_id` set to nil.

### RuboCop Notes

- `RSpec/DescribeClass` allows string describes that match `/^(?:(?:::)?[A-Z]\w*)+$/` — so `"Fidelity"` passes but `"Concerns Fidelity"` (with a space) does not. Use `"ConcernsFidelity"` instead.
- `Style/ExplicitBlockArgument` triggers when a helper method just wraps another method with `yield` and no other code. Use `# rubocop:disable`/`# rubocop:enable` or add content inside the block.

### Testing Notes

- Concern logic is validated in the generated app (T32), not the gem suite. The gem suite only tests the generator code (file creation, idempotency, content checks).
- Fidelity specs render each `.tt` template with ERB and compare to the canonical fixture using `match_canonical`. Since the concern templates are verbatim (no ERB), the rendered output equals the fixture byte-for-byte.

## Strict Loading Generator (Task 16)

The strict_loading generator creates a single initializer `config/initializers/strict_loading.rb` that configures ActiveRecord strict loading without editing `config/application.rb`.

### Key Decisions

1. **Initializer over application.rb injection**: The task explicitly preferred the initializer approach to avoid fragile `inject_once` into `config/application.rb`. A single `config/initializers/strict_loading.rb.tt` template sets all three config values in one file.

2. **Per-env violation via case statement**: Instead of generating separate env-specific initializers or editing `config/environments/*.rb`, the initializer uses a `case Rails.env` block inside `Rails.application.configure do`. Test env raises (`:raise`); all other envs (development, production) log (`:log`). This keeps everything in one file and is evaluated at boot time per environment.

3. **Config values set**: `strict_loading_by_default = true`, `strict_loading_mode = :n_plus_one_only`, `strict_loading_violation` = `:raise` (test) / `:log` (dev, prod).

### Generator Methods

1. `create_strict_loading_initializer` - generates `config/initializers/strict_loading.rb` from template

### Idempotency

The `template` method overwrites the file on each run, making it idempotent by nature. No `inject_once` needed since no existing files are modified.

### Spec Coverage

9 tests covering:
- destination_root binding
- File existence
- frozen_string_literal comment
- strict_loading_by_default = true
- strict_loading_mode = :n_plus_one_only
- :raise in test env
- :log in dev/prod
- strict_loading_violation config key present
- Idempotency (run twice, verify identical output)

## Maintenance Generator (Task 17)

The maintenance generator adds the `maintenance_tasks` gem (Shopify), mounts the engine at `/maintenance_tasks`, and templates an example task plus a rake task.

### Key Decisions

1. **Example task structure**: Based on the maintenance_tasks gem API (`MaintenanceTasks::Task` with `collection`, `count`, `process`). The example uses `User.in_batches(of: 1000)` for collection, `User.count` for count, and `batch.update_all(updated_at: Time.current)` for process. This mirrors the real task patterns in looper_core (e.g. `BackfillMatchHasScreenshotTask`).

2. **Rake task pattern**: Authored a minimal `maintenance_counters.rake` with two tasks: `update_counters` (eager loads models, iterates descendants) and `purge_stale` (RETENTION_DAYS env var, cutoff date). Modeled on looper_core's `counters.rake` and `data_retention.rake` but kept minimal and illustrative.

3. **Route mounting**: Uses `insert_route` from base class with `mount MaintenanceTasks::Engine, at: "/maintenance_tasks"`. Idempotent via the base class's content-inclusion guard.

### Generator Methods

1. `add_maintenance_tasks_gem` - adds `maintenance_tasks` gem via `add_gem`
2. `insert_maintenance_tasks_route` - mounts engine at `/maintenance_tasks` via `insert_route`
3. `create_example_task` - generates `app/tasks/maintenance/example_task.rb` from template
4. `create_rake_task` - generates `lib/tasks/maintenance_counters.rake` from template

### Spec Coverage

13 tests covering:
- destination_root binding
- Gem addition
- Route insertion
- Example task file existence + structure (class, collection, process)
- frozen_string_literal on both generated files
- Rake task file existence + namespace/tasks
- Idempotency for gem, route, example task, and rake task (4 tests)

### maintenance_tasks Gem API

The gem requires tasks to be in `app/tasks/maintenance/` and subclass `MaintenanceTasks::Task`. Required methods: `collection` (returns AR Relation, BatchEnumerator, or Array) and `process(item)`. Optional: `count` for progress reporting. The gem provides a web UI at the mount point for queuing, pausing, and monitoring tasks.

## Frontend Core Generator (Task 18)

The frontend_core generator adds importmap-rails, pagy (conditionally), and annotaterb, plus their configuration files.

### Key Decisions

1. **class_option for skip_pagy**: Uses `class_option :skip_pagy, type: :boolean, default: false` to allow opting out of Pagy. In specs, pass `"skip_pagy" => true` as the options hash (second argument to `.new`). Thor does NOT apply class_option defaults when instantiating directly in tests, so `options[:skip_pagy]` is `nil` (falsy) by default and `true` when explicitly set. This works correctly with `return if options[:skip_pagy]` since `nil` is falsy.

2. **Importmap config**: Based on inscripto-v2's `config/importmap.rb` (fetched via `gh api`). Trimmed to a sensible default for a new Rails app: application pin, Hotwire (turbo-rails, stimulus, stimulus-loading), Trix/actiontext, activestorage, and `pin_all_from` for app/javascript/controllers.

3. **Pagy initializer**: Based on looper_core's pagy initializer but trimmed to only the 4 required extras (arel, array, countless, bootstrap) plus `Pagy::DEFAULT[:limit] = 25` and `Pagy::DEFAULT.freeze`. The looper_core version has many more extras commented out; we keep it minimal.

4. **Annotaterb config (models-only)**: The `.annotaterb.yml` uses symbol keys (e.g. `:models: true`) matching the YAML dump format from `AnnotateRb::ConfigGenerator.default_config_yml`. Models-only means: `models: true`, `routes: false`, `active_admin: false`, and all `exclude_*` keys set to `true` (tests, fixtures, factories, serializers, controllers, helpers, scaffolds). The `additional_file_patterns: []` key is also included.

### Generator Methods

1. `add_frontend_gems` - adds importmap-rails and annotaterb (group: :development)
2. `add_pagy_gem` - adds pagy gem (skipped when `options[:skip_pagy]`)
3. `create_importmap_config` - generates config/importmap.rb from template
4. `create_pagy_initializer` - generates config/initializers/pagy.rb (skipped when `options[:skip_pagy]`)
5. `create_annotaterb_config` - generates .annotaterb.yml from template

### Spec Coverage (Both Branches)

22 tests covering:
- destination_root binding
- Gem additions: importmap-rails, annotaterb (with development group), pagy (default), pagy absent with skip_pagy
- Importmap: file existence, pin content, frozen_string_literal
- Pagy: file existence (default), absent with skip_pagy, backend extras (arel/array/countless), bootstrap extra, frozen_string_literal
- Annotaterb: file existence, models-only config (models true, routes false, active_admin false, exclude_* true), generated with skip_pagy too
- Importmap generated with skip_pagy too
- Idempotency: gems, importmap, pagy initializer, annotaterb config (4 tests)

### Annotaterb Configuration Keys

From `lib/annotate_rb/options.rb` in the annotaterb gem:
- `FLAG_OPTIONS`: boolean keys like `exclude_tests`, `exclude_fixtures`, `exclude_factories`, `exclude_serializers`, `exclude_controllers`, `exclude_helpers`, `exclude_scaffolds`, `classified_sort`, `show_indexes`, `show_foreign_keys`
- `OTHER_OPTIONS`: `active_admin`, `models`, `routes`, `additional_file_patterns`
- `POSITION_OPTIONS`: `position` (nil/before/top/after/bottom)

The YAML uses symbol-prefixed keys (`:models: true`) because `YAML.dump` on a hash with symbol keys produces this format.

## Docs Render Generator (Task 19)

The docs_render generator adds Redcarpet (Markdown to HTML), Rouge (syntax highlighting), and Mermaid (client-side diagram rendering) to a Rails app, along with a DocsController and Document model for serving markdown documentation.

### Canonical Sources

- **Verbatim files**: `app/models/document.rb` (Document model with inline Redcarpet::Render::HTML subclass and Rouge syntax highlighting), `app/javascript/docs.js` (Mermaid client-side rendering), `app/assets/stylesheets/documentation.scss` (docs styling with dark mode support). All three are byte-identical to looper_core fixtures.
- **Adapted files**: `app/controllers/docs_controller.rb` is adapted from looper_core (changed `AdminController` to `ApplicationController` for generic use). `app/views/docs/show.html.erb.tt` is adapted from looper_core's `show.html.haml` (converted HAML to ERB, removed app-specific helpers like `content_header` and `shared/box` partial).
- **Authored files**: `config/initializers/redcarpet_rouge.rb` is authored (looper_core has no separate redcarpet/rouge initializer; the Document model handles all configuration inline).

### ERB-in-ERB Escaping for View Templates

The `show.html.erb.tt` template contains app-level ERB that must be preserved literally in the generated `.html.erb` file. Use `<%%` (double percent) to escape `<%` so Thor's template engine outputs literal `<%` instead of evaluating it at generation time:

```
<%% content_for :head do %>
  <%%= javascript_include_tag 'docs', 'data-turbo-track': 'reload' %>
<%% end %>
```

This produces the correct ERB output in the generated `show.html.erb`:
```erb
<% content_for :head do %>
  <%= javascript_include_tag 'docs', 'data-turbo-track': 'reload' %>
<% end %>
```

### Document Model Architecture

The Document model is a plain Ruby class (includes `ActiveModel::Model`) that:
1. Reads markdown files from `docs/` directory via `Rails.root.glob`
2. Uses a custom `Redcarpet::Render::HTML` subclass (`Document::Renderer`) with:
   - Obsidian wikilink support (`[[Note]]`, `[[Note#Heading]]`, `[[Note|Alias]]`)
   - Callout blocks (`> [!NOTE]`, `> [!TIP]`, etc.)
   - Mermaid diagram detection (language == 'mermaid' emits `<pre class="mermaid">` instead of syntax highlighting)
   - Rouge syntax highlighting with Github dark theme
3. Sanitizes HTML output with extended allowed tags/attributes

### Route Pattern

The route `get "docs(/*id)" => "docs#show"` uses a glob parameter to match nested paths like `/docs`, `/docs/README`, `/docs/platform-guide/AUDITS`. The `(*id)` syntax makes the parameter optional.

### Generator Methods

1. `add_docs_gems` - adds redcarpet and rouge gems
2. `create_docs_controller` - generates app/controllers/docs_controller.rb
3. `create_document_model` - generates app/models/document.rb (verbatim)
4. `create_docs_views` - generates app/views/docs/show.html.erb (adapted from HAML)
5. `create_docs_javascript` - generates app/javascript/docs.js (verbatim)
6. `create_docs_stylesheet` - generates app/assets/stylesheets/documentation.scss (verbatim)
7. `create_redcarpet_rouge_initializer` - generates config/initializers/redcarpet_rouge.rb (authored)
8. `insert_docs_route` - inserts `get "docs(/*id)" => "docs#show"` route

### Spec Coverage

28 tests covering:
- destination_root binding
- Gem additions (redcarpet, rouge)
- Controller existence, inheritance, frozen_string_literal
- Document model existence, Redcarpet/Rouge references, frozen_string_literal
- View existence, document render, javascript include
- JS existence, mermaid import
- Stylesheet existence, documentation section
- Initializer existence, Redcarpet/Rouge mentions, frozen_string_literal
- Route insertion
- Idempotency for gems, route, controller, model, view, JS, stylesheet, initializer (8 tests)

### Fidelity Specs

3 fidelity specs for verbatim files:
- `document.rb` matches canonical fixture
- `docs.js` matches canonical fixture
- `documentation.scss` matches canonical fixture

## Doc Specs Generator (Task 20)

The doc_specs generator creates a self-documenting system spec pipeline: `bin/generate-docs` (parses `@category`/`@order` doc-comments + `doc_screenshot` calls from system specs to produce markdown + screenshots), a `doc_screenshot` Capybara helper, a `docs:check` rake task, and an example annotated system spec.

### Canonical Sources

- **Verbatim file**: `bin/generate-docs` is copied byte-for-byte from `LooperInsights/looper_core/bin/generate-docs`. It is a Ruby script (shebang `#!/usr/bin/env ruby`), not bash as the task description stated. It is excluded from SimpleCov coverage via the `/templates/` filter. Fidelity spec verifies the `.tt` template renders identically to the fixture.
- **Authored file**: `spec/support/doc_screenshot_helper.rb` is extracted from looper_core's `spec/rails_helper.rb` where `doc_screenshot` was defined as an inline anonymous module (`config.include Module.new { def doc_screenshot... }`). Authored as a standalone `DocScreenshotHelper` module with `RSpec.configure` to include it for `type: :system`.
- **Adapted file**: `lib/tasks/docs_check.rake` is extracted from looper_core's `Rakefile` where the `docs:check` namespace was defined inline. Adapted into a standalone rake file.
- **Authored file**: `spec/system/example_doc_spec.rb` demonstrates the `@category`, `@order`, and `doc_screenshot` pattern on a fresh app.

### Generator Methods

1. `create_generate_docs_script` - templates `bin/generate-docs` and calls `File.chmod(0o755, dest)` to make it executable
2. `create_doc_screenshot_helper` - templates `spec/support/doc_screenshot_helper.rb`
3. `create_docs_check_rake_task` - templates `lib/tasks/docs_check.rake`
4. `create_example_system_spec` - templates `spec/system/example_doc_spec.rb`

### Key Decisions

1. **No `File.exist?` guard on chmod**: Initially added `File.chmod(0o755, dest) if File.exist?(dest)` as defensive code, but this created an uncovered branch (the false path can't be reached since `template` always creates the file). Removed the guard for 100% branch coverage. The `template` method always creates the destination file, so the guard was unnecessary.

2. **ERB safety of bin/generate-docs**: The script contains `#{...}` Ruby string interpolations and `<<~` heredocs, but no `<%` or `<%=` sequences, so it is safe to process through Thor's ERB template engine as a `.tt` file.

3. **doc_screenshot helper location**: Placed in `spec/support/` (not `app/helpers/`) because it is a test-only helper included via `RSpec.configure` for `type: :system` specs, matching looper_core's pattern.

### Spec Coverage

22 tests covering:
- destination_root binding
- bin/generate-docs: existence, executable bit, ruby shebang, frozen_string_literal
- doc_screenshot_helper: existence, doc_screenshot method, frozen_string_literal, RSpec configure
- docs_check.rake: existence, namespace + task, frozen_string_literal
- example_doc_spec: existence, @category, @order, doc_screenshot call, frozen_string_literal
- Idempotency: bin/generate-docs, doc_screenshot_helper, docs_check.rake, example_doc_spec, executable bit preserved (5 tests)

### Fidelity Specs

1 fidelity spec for verbatim file:
- `bin/generate-docs` matches canonical fixture

## Agents Docs Generator (Task 21)

The agents_docs generator creates root `AGENTS.md`, three adapted docs (`docs/development.md`, `docs/testing.md`, `docs/performance.md`), a verbatim PR template, and Faraday + VCR/WebMock support files with an example API spec.

### Canonical Sources

- **Adapted files**: `AGENTS.md`, `docs/development.md`, `docs/testing.md`, `docs/performance.md` are adapted from `develoz-com/agent`. The source AGENTS.md is titled "# CLAUDE.md" but the adapted version uses "# AGENTS.md". All `bin/run` and `bin/develoz_agent` references are replaced with standard `bin/rails` / `bundle exec` commands. Agent-specific sections (develoz_agent CLI, ticket-state-machine docs, Jira API caching, opencode/git worktree stubs, database-backups container) are removed. Generic patterns (Docker-first, coverage requirements, N+1 detection, query patterns, caching) are retained.
- **Verbatim file**: `.github/pull_request_template.md` is copied byte-for-byte from `develoz-com/inscripto-v2`. The fixture already exists at `spec/fixtures/canonical/develoz-com-inscripto-v2/.github/pull_request_template.md` (from T6 demo), so no new fixture was needed. A new fidelity spec (`spec/fidelity/agents_docs_fidelity_spec.rb`) verifies the agents_docs template matches the same fixture.
- **Authored files**: `spec/support/vcr.rb.tt` (VCR config with WebMock), `spec/support/faraday.rb.tt` (FaradayFactory module with retry middleware), `spec/requests/example_api_spec.rb.tt` (demonstrates VCR + Faraday pattern), `spec/cassettes/Example_API/fetches_data_from_an_external_API.yml.tt` (stub VCR cassette fixture).

### Generator Methods

1. `add_api_gems` - adds faraday, faraday-retry (default group); vcr, webmock (test group)
2. `create_agents_md` - templates AGENTS.md
3. `create_docs` - templates docs/development.md, docs/testing.md, docs/performance.md
4. `create_pr_template` - templates .github/pull_request_template.md
5. `create_vcr_support` - templates spec/support/vcr.rb
6. `create_faraday_support` - templates spec/support/faraday.rb
7. `create_example_api_spec` - templates spec/requests/example_api_spec.rb + stub cassette

### Gem Idempotency Test Pitfall

When testing gem idempotency for `faraday` and `faraday-retry`, `gemfile.scan("faraday")` matches both gems (2 occurrences). Use a regex anchored to the gem declaration: `gemfile.scan(/^\s*gem\s+["']faraday["']/m).length` to count only exact `gem "faraday"` lines, not `gem "faraday-retry"`.

### VCR Cassette as Template

The stub VCR cassette is a YAML file with no ERB content, but it is processed through Thor's `template` method (with `.tt` extension) for consistency with the generator pattern. Since the YAML contains no `<%` sequences, ERB processing is a no-op and the output is identical to the source.

### Spec Coverage

39 tests covering:
- destination_root binding
- 4 gem additions (faraday, faraday-retry, vcr, webmock)
- AGENTS.md existence, content (Quality Expectations, docs references)
- 3 docs existence + content (development Command Reference, testing coverage requirement, performance N+1 Detection)
- PR template existence + content (Changes section)
- vcr.rb existence, frozen_string_literal, cassette_library_dir, hook_into :webmock
- faraday.rb existence, frozen_string_literal, FaradayFactory module, :retry middleware
- example spec existence, frozen_string_literal, :vcr metadata, FaradayFactory usage
- cassette existence, http_interactions content
- 7 idempotency tests (gems, AGENTS.md, docs, PR template, vcr.rb, faraday.rb, example spec, cassette)

### Fidelity Specs

1 fidelity spec for verbatim file:
- `.github/pull_request_template.md` matches canonical fixture (reuses existing inscripto-v2 fixture)

## Versioning Generator (Task 36)

The versioning generator replicates inscripto-v2's app versioning scheme: an `APP_VERSION` constant, an `app_version` helper, and a reusable display partial.

### Canonical Sources

- **Verbatim (method snippet)**: The `app_version` method (`def app_version; APP_VERSION; end`) is copied verbatim from inscripto-v2's `app/helpers/application_helper.rb`. Stored as fixture `spec/fixtures/canonical/develoz-com-inscripto-v2/app/helpers/app_version.rb`. Fidelity spec verifies the rendered `application_helper.rb.tt` template includes the fixture content.
- **Adapted (constant injection)**: The `APP_VERSION = ENV.fetch("APP_VERSION", "dev")` line is adapted from inscripto-v2's `config/constants.rb`. Instead of creating a separate file, it is injected into the app's existing `config/initializers/constants.rb` (created by T10's tooling generator) via `inject_once` after the `# additional constants appended by generators` marker.
- **Authored (partial)**: The `_app_version.html.erb.tt` partial is authored, extracted from inscripto-v2's inline sidebar version display (`app/views/layouts/_admin_sidebar_nav.html.erb`) into a reusable partial.

### Generator Methods

1. `inject_app_version_constant` - injects `APP_VERSION = ENV.fetch("APP_VERSION", "dev")` into `config/initializers/constants.rb` after the marker comment, idempotently via `inject_once`
2. `create_application_helper` - if `app/helpers/application_helper.rb` exists, injects the `app_version` method via `inject_once` with `before: /^end\s*$/`; else creates the file from template
3. `create_app_version_partial` - templates `app/views/shared/_app_version.html.erb` from `.erb.tt`

### Consumer-Side Integrations (NOT in T36)

T36 only provides the core constant + helper + partial. The following consumer-side integrations are handled by their respective tasks:
- **T25 (admin)**: Admin sidebar should render `<%= render "shared/app_version" %>` to display the version
- **T26 (PWA)**: Service worker should use `APP_VERSION` for `CACHE_VERSION`
- **T30 (kamal)**: Deploy config should pass `APP_VERSION` as an env var to the container

### Key Decisions

1. **inject_once for both constants.rb and application_helper.rb**: The `inject_once` base class helper provides idempotency through content-inclusion checking. For constants.rb, the `after:` parameter targets the marker comment. For application_helper.rb, the `before: /^end\s*$/` parameter targets the module's closing `end`.

2. **Both branches of application_helper.rb tested**: The `if File.exist?` branch has two paths - inject (file exists) and create (file absent). Both are tested with seeded fixtures. The inject branch seeds an existing helper with an `existing_method`, then verifies both methods coexist.

3. **ERB-in-ERB escaping for partial**: The `_app_version.html.erb.tt` template uses `<%%` and `<%%=` to escape ERB tags so Thor's template engine outputs literal `<%` and `<%=` in the generated `.erb` file.

4. **Anonymous block forwarding for with_tmp_dir**: Ruby 4.0's anonymous block forwarding (`&` without name) avoids `Style/ExplicitBlockArgument` and `Naming/BlockForwarding` cops.

### Spec Coverage

13 tests covering:
- destination_root binding
- APP_VERSION injection into constants.rb (content, position after marker, idempotency)
- application_helper.rb creation (content, frozen_string_literal, idempotency)
- application_helper.rb injection (method coexists with existing, idempotency)
- Partial creation, content, idempotency

### Fidelity Specs

1 fidelity spec:
- `app_version` method in rendered template matches canonical inscripto-v2 fixture

## Task 9 - InstallGenerator (Meta-Generator Invocation)

### The Core Problem
The install generator must invoke sub-generators (tooling, testing, solid, etc.) programmatically. Standard Thor invocation mechanisms ALL FAIL:
- `invoke_all` - treats base-class helpers (`inject_once`, `add_gem`) as tasks, raises "no such task"
- `generate` / `Rails::Generators.invoke` - same Thor task-resolution failure
- `Rails::Generators.invoke` with explicit args - same failure path

### The Working Approach: Direct Instantiation + public_instance_methods(false)
Instead of Thor's invocation chain, directly require the generator file, instantiate it bound to `destination_root`, and call each public method defined in the SUBCLASS:

```ruby
def invoke_generator(name)
  require "generators/develoz/#{name}/#{name}_generator"
  klass = Develoz::Generators.const_get("#{name.camelize}Generator")
  gen = klass.new([], {}, destination_root: destination_root)
  klass.public_instance_methods(false).each { |method| gen.public_send(method) }
rescue LoadError, NameError
  say "generator develoz:#{name} not yet available", :yellow
end
```

**Why `public_instance_methods(false)`**: The `false` argument excludes inherited methods. This is critical because `Develoz::Generators::Base` defines helper methods (`inject_once`, `add_gem`, `insert_route`, etc.) that are NOT generator steps - they're utilities called BY the steps. Without `false`, Thor would try to call those helpers as standalone steps, causing errors or duplicate execution.

**Why `klass.new([], {}, destination_root: destination_root)`**: The `[]` is args (empty), `{}` is options (empty hash - sub-generators get their own class_options, not the install generator's), and `destination_root:` binds all file operations to the target directory. This is the same signature Thor uses internally.

### Rescue Branch for Not-Yet-Available Generators
Opt-in generators (api, auth, pwa, etc.) don't have generator files yet. The `require` raises `LoadError`, caught by the rescue, which prints a yellow warning. This is tested by calling `invoke_generator("api")` directly and asserting `/not yet available/` on stdout.

### Idempotency
The install generator is idempotent because every sub-generator's methods are idempotent (via `inject_once` content-checking, `add_gem` regex matching, Thor's `template` "identical" behavior). Running install twice produces no duplicate Gemfile entries.

### RuboCop Notes
- `build_options` originally had 24 ABC size (limit 17) due to 11 `options[:flag]` lookups. Fixed by extracting `OPTION_FLAGS` constant and using `index_with` to build the hash dynamically.
- Constants defined under `private` need `private_constant :NAME` - the `private` keyword does NOT affect constant visibility (triggers `Lint/UselessConstantScoping`).

## Task 8 - CLI (Thor-based entry point)

### Overview

The CLI (`lib/develoz/cli.rb`) is the user-facing entry point. It provides `develoz version` and `develoz new APP_NAME` commands. The `new` command resolves opt-in flags, resolves Ruby/Rails versions via `VersionResolver`, runs `rails new`, writes version files, and invokes the `InstallGenerator`.

### Thor Boolean Option Behavior (VERIFIED)

Thor boolean options WITHOUT `default:`:
- `options[:flag]` is `nil` when the flag is NOT passed
- `options[:flag]` is `true` when `--flag` is passed

So `options[flag].nil?` correctly means "not passed". This is used in `resolve_flag` to distinguish between "user explicitly passed `--api`" (use the value) and "user didn't pass it" (prompt or default to false with `--yes`).

### require_relative Path

The prompt specified `require_relative "develoz/version"` but `cli.rb` lives at `lib/develoz/cli.rb`. `require_relative` resolves relative to the current file, so `require_relative "develoz/version"` from `lib/develoz/cli.rb` looks for `lib/develoz/develoz/version.rb` (wrong). The correct path is `require_relative "version"` since the file is already inside the `develoz/` directory.

### RuboCop Fixes Applied

1. `each_with_object({}) { |flag, h| h[flag] = resolve_flag(flag) }` -> `to_h { |flag| [flag, resolve_flag(flag)] }` (Rails/IndexWith, Style/ReduceToHash)
2. Empty line after guard clause (`return false if options[:yes]`)
3. `Performance/ConstantRegexp` - append `/o` to `/develoz #{Develoz::VERSION}/o`
4. `RSpec/AnyInstance` and `RSpec/MultipleExpectations` - disabled with `# rubocop:disable`/`# rubocop:enable` block, matching the pattern in `canonical_fetcher_spec.rb`

### Spec Strategy

The spec stubs `VersionResolver`, `InstallGenerator`, `system`, and `Dir.chdir` to test the CLI in isolation without actually running `rails new`. `allow_any_instance_of` is used for `system` because the CLI calls it as a private method on the instance, and there's no way to get the instance reference before `described_class.start` creates it.

## API Generator (Task 22)

The api generator adds Blueprinter, RSwag (api/ui/specs), generates a versioned API base controller, blueprinter initializer with LowerCamelTransformer, rswag initializers, mounts rswag routes, and creates an example rswag request spec.

### Canonical Sources

- **Adapted files**: All templates are adapted from `LooperInsights/looper_core`:
  - `app/controllers/api/v1/base_controller.rb.tt` adapted from looper_core's `app/controllers/api/v3/base_controller.rb`. Key changes: v3→v1 namespace, removed all Cognito/auth_validation dependencies (`context`, `ensure_authenticated`, `valid_token?`, `admin_logged_in?`, `scoped_client`, `user_id`, `user_email`), replaced with a simple `def authenticate; end` stub (no-op by default, override in subclasses). Retained: `Pagy::Backend`, `render_json_error`, `render_resource`/`render_resources`, `render_json`, `paginated`, `meta`, `common_params`, `default_page_size` class method, `rescue_from` for RecordNotFound/RecordInvalid.
  - `config/initializers/blueprinter.rb.tt` adapted from looper_core's `config/initializers/blueprinter.rb`. Kept `LowerCamelTransformer` class (verbatim) and `default_transformers` + `datetime_format`. Removed `BlueprinterActiveRecord::Preloader` (requires separate `blueprinter-activerecord` gem not added) and the `unless` lambda (app-specific).
  - `config/initializers/rswag_api.rb.tt` adapted from looper_core (added `# frozen_string_literal: true`, otherwise verbatim).
  - `config/initializers/rswag_ui.rb.tt` adapted from looper_core (endpoint label changed from 'Looper Core API V3' to 'API V1', path v3→v1, added frozen_string_literal).
- **Authored files**: `app/blueprints/example_blueprint.rb.tt` (minimal blueprint inheriting `Blueprinter::Base` directly, since the generated app has no `BaseBlueprint`), `spec/requests/api/v1/examples_spec.rb.tt` (minimal rswag spec demonstrating `path`/`response`/`schema` DSL, no auth dependencies).

### No v3→v1 Chain Pattern

LooperInsights/looper_core has `Api::V3::BaseController < ApplicationController` directly. There is no intermediate `Api::ApplicationController` or `Api::V3::ApplicationController`. Therefore, the `app/controllers/api/v1/application_controller.rb.tt` template was NOT created (the task said "if looper_core has the v3→v1 chain pattern").

### No Fidelity Specs

All T22 templates are adapted (not verbatim) from looper_core. The primary differences are: added `# frozen_string_literal: true` (looper_core files lack it), removed Cognito dependencies, simplified for a new Rails app. Since there are no byte-identical verbatim files, no fidelity specs were created.

### Install Generator Spec Update

The install generator spec (`install_generator_spec.rb`) had a test "warns when a generator is not yet available" that used `invoke_generator("api")` as the not-yet-available example. Since T22 creates the api generator, this test was updated to use `invoke_generator("auth")` instead (auth is still not implemented).

### Generator Methods

1. `add_api_gems` - adds blueprinter, rswag-api, rswag-ui (default group); rswag-specs (test group)
2. `create_base_controller` - templates `app/controllers/api/v1/base_controller.rb`
3. `create_blueprinter_initializer` - templates `config/initializers/blueprinter.rb`
4. `create_example_blueprint` - templates `app/blueprints/example_blueprint.rb`
5. `create_rswag_api_initializer` - templates `config/initializers/rswag_api.rb`
6. `create_rswag_ui_initializer` - templates `config/initializers/rswag_ui.rb`
7. `insert_rswag_routes` - mounts `Rswag::Ui::Engine` and `Rswag::Api::Engine` at `/api-docs` via `insert_route`
8. `create_example_request_spec` - templates `spec/requests/api/v1/examples_spec.rb`

### Spec Coverage

36 tests covering:
- destination_root binding
- 4 gem additions (blueprinter, rswag-api, rswag-ui, rswag-specs)
- Base controller: existence, frozen_string_literal, inheritance, Pagy::Backend, authenticate stub, render_json_error
- Blueprinter initializer: existence, LowerCamelTransformer, default_transformers, frozen_string_literal
- Example blueprint: existence, Blueprinter::Base inheritance
- RSwag initializers: rswag_api existence + openapi_root, rswag_ui existence + openapi_endpoint + v1 swagger
- Routes: rswag ui mount, rswag api mount
- Example spec: existence, frozen_string_literal, path DSL, response DSL
- Idempotency: gems, base controller, blueprinter initializer, example blueprint, rswag_api, rswag_ui, routes, example spec (8 tests)

### RuboCop Notes

- `Style/RedundantRegexpArgument` triggers on `routes.scan(/mount Rswag::Ui::Engine/)` when the argument contains no regex metacharacters. Use a plain string instead: `routes.scan("mount Rswag::Ui::Engine")`.

## Auth Generator (Task 23)

The auth generator scaffolds Rails 8's built-in authentication (equivalent to `bin/rails generate authentication`), adapted for the develoz-rails template pattern.

### Canonical Sources

- **Adapted files**: All templates are adapted from the Rails 8 authentication generator source (`rails/rails` repo, `railties/lib/rails/generators/rails/authentication/templates/`):
  - `app/models/user.rb.tt` adapted from Rails 8's `user.rb.tt`. Key changes: uses `email` instead of `email_address`, adds explicit `validates :email` with `URI::MailTo::EMAIL_REGEXP` (Rails 8 relies on `normalizes` + DB uniqueness only). Kept `has_secure_password` and `normalizes :email`.
  - `app/models/current.rb.tt` adapted from Rails 8's `current.rb.tt`. Key change: uses `attribute :user` directly instead of `attribute :session` with `delegate :user, to: :session` (no Session model in this simplified version).
  - `app/controllers/concerns/authentication.rb.tt` adapted from Rails 8's `authentication.rb.tt`. Key changes: uses `Current.user` instead of `Current.session`, `cookies.signed[:user_id]` instead of `cookies.signed[:session_id]`, renamed `allow_unauthenticated_access` to `allow_authentication_as` (per task spec), removed `start_new_session_for`/`terminate_session` Session model logic (simplified to set `Current.user` directly).
  - `app/controllers/sessions_controller.rb.tt` adapted from Rails 8's `sessions_controller.rb.tt`. Key change: uses `email` instead of `email_address` in `authenticate_by` params.
  - `app/controllers/passwords_controller.rb.tt` adapted from Rails 8's `passwords_controller.rb.tt`. Key changes: uses `email` instead of `email_address`, removed conditional `<%- if defined?(ActionMailer::Railtie) -%>` ERB guards (always include mailer-dependent code since these are templates for a Rails app that will have ActionMailer).
  - `app/mailers/passwords_mailer.rb.tt` adapted from Rails 8's `passwords_mailer.rb.tt`. Key change: `to: user.email` instead of `to: user.email_address`.
  - `app/views/sessions/new.html.erb.tt` adapted from Rails 8 ERB template engine's `sessions/new.html.erb`. Key change: `:email` field instead of `:email_address`.
  - `app/views/passwords/edit.html.erb.tt` adapted from Rails 8 ERB template engine's `passwords/edit.html.erb`. Verbatim except for `<%%` ERB escaping.
  - `app/views/passwords_mailer/reset.html.erb.tt` adapted from Rails 8's `passwords_mailer/reset.html.erb.tt`. Verbatim except for `<%%` ERB escaping.
- **Authored files**: `db/migrate/create_users.rb.tt` (Rails 8 generates migrations via `rails g migration` at runtime, not as a template; we author a static migration template with `email` + `password_digest` columns and unique index). `spec/requests/sessions_spec.rb.tt` and `spec/requests/passwords_spec.rb.tt` (Rails 8 generates these via `hook_for :test_framework`; we author minimal request specs demonstrating sign in/out and password reset flows).

### Rails 8 Authentication Architecture (Latest vs Task Spec)

The Rails 8 authentication generator on `main` has evolved to use a `Session` model (with `ip_address` and `user_agent` columns) and `email_address` field. The task spec asks for the simpler earlier version: `Current.user` directly (no Session model), `email` field. The templates follow the task spec, not the latest `main` branch.

### Rails 8 Password Reset Token

Rails 8's `has_secure_password` includes `password_reset_token` and `find_by_password_reset_token!` methods (derived from the password digest via `ActiveSupport::MessageVerifier`). The passwords controller and mailer view use these methods. No additional database columns are needed for password reset tokens.

### ERB-in-ERB Escaping for View Templates

All `.html.erb.tt` view templates use `<%%` and `<%%=` to escape ERB tags so Thor's template engine outputs literal `<%` and `<%=` in the generated `.erb` files. This is the same pattern used by T19 (docs_render) and T36 (versioning).

### Install Generator Spec Update

The install generator spec had a test "warns when a generator is not yet available" that used `invoke_generator("auth")` as the not-yet-available example (set in T22 when api was created). Since T23 creates the auth generator, this test was updated to use `invoke_generator("pwa")` instead (pwa is still not implemented). This is the same pattern as T22's update from "api" to "auth".

### Generator Methods

1. `add_bcrypt_gem` - adds bcrypt gem via `add_gem`
2. `create_user_model` - templates `app/models/user.rb`
3. `create_current_model` - templates `app/models/current.rb`
4. `create_authentication_concern` - templates `app/controllers/concerns/authentication.rb`
5. `create_sessions_controller` - templates `app/controllers/sessions_controller.rb`
6. `create_passwords_controller` - templates `app/controllers/passwords_controller.rb`
7. `create_passwords_mailer` - templates `app/mailers/passwords_mailer.rb`
8. `create_sessions_views` - templates `app/views/sessions/new.html.erb`
9. `create_passwords_views` - templates `app/views/passwords/edit.html.erb`
10. `create_passwords_mailer_views` - templates `app/views/passwords_mailer/reset.html.erb`
11. `create_users_migration` - templates `db/migrate/create_users.rb`
12. `insert_auth_routes` - inserts `resource :session` and `resources :passwords, param: :token` routes via `insert_route`
13. `create_sessions_request_spec` - templates `spec/requests/sessions_spec.rb`
14. `create_passwords_request_spec` - templates `spec/requests/passwords_spec.rb`

### Spec Coverage

59 tests covering:
- destination_root binding
- bcrypt gem addition
- User model: existence, has_secure_password, normalizes email, validates email, frozen_string_literal
- Current model: existence, attribute :user, CurrentAttributes inheritance
- Authentication concern: existence, before_action, resume_session, request_authentication, after_authentication_url, allow_authentication_as, frozen_string_literal
- Sessions controller: existence, new/create/destroy actions, frozen_string_literal
- Passwords controller: existence, edit/update actions, frozen_string_literal
- Passwords mailer: existence, reset method, frozen_string_literal
- Sessions view: existence, form_with
- Passwords view: existence, form_with
- Mailer view: existence, edit_password_url
- Migration: existence, email column, password_digest column, unique index, frozen_string_literal
- Routes: session route, passwords route
- Request specs: sessions existence + frozen_string_literal + describe, passwords existence + frozen_string_literal + describe
- Idempotency: bcrypt gem, user model, current model, authentication concern, sessions controller, passwords controller, passwords mailer, sessions view, passwords view, mailer view, migration, routes, sessions spec, passwords spec (14 tests)

## UI Generator (Task 24)

The ui generator sets up the `develoz_ui` gem as a git submodule at `vendor/develoz-ui`, with env-conditional Gemfile entries, a `.gitmodules` section, a setup script, and importmap pins for Stimulus controllers.

### Key Decisions

1. **inject_once for Gemfile (not add_gem)**: The base class `add_gem` has an idempotency guard that checks for ANY `gem "develoz_ui"` line in the Gemfile. Since we need TWO declarations (one in `group :development, :test` with `path:`, one in `group :production` with `github:`), calling `add_gem` twice would skip the second call. Instead, use `inject_once` with a multi-line content block containing both group declarations. The content-inclusion guard ensures the entire block is only injected once.

2. **.gitmodules creation + injection**: The base class `inject_once` returns early if the target file doesn't exist (`return unless File.exist?(file_path)`). For `.gitmodules`, which may not exist yet, the generator first creates an empty file via `File.write` if it doesn't exist, then calls `inject_once` to append the submodule section. Both branches (file exists / doesn't exist) are tested for 100% coverage.

3. **Bash setup script (not Ruby)**: The `bin/setup_develoz_ui` script is a bash script (`#!/usr/bin/env bash`) rather than Ruby, since it runs `git submodule update --init --recursive`. The script includes error handling: if the submodule directory is empty or missing after the update, it prints an error message and exits 1. The `.tt` template is processed through Thor's ERB engine, but since the script contains no `<%` sequences, ERB processing is a no-op.

4. **Importmap pins**: Injects two pins into `config/importmap.rb` via `inject_once`: `pin "develoz-ui"` for the main entry point and `pin_all_from` for Stimulus controllers under `develoz-ui/controllers`. The spec seeds a minimal importmap.rb fixture with existing pins to verify both preservation of existing content and injection of new pins.

### Generator Methods

1. `add_develoz_ui_gems` - injects two group blocks into Gemfile via `inject_once` (dev/test with `path:`, production with `github:`)
2. `create_gitmodules` - creates `.gitmodules` if absent, then injects submodule section via `inject_once`
3. `create_setup_script` - templates `bin/setup_develoz_ui` and chmods to 0o755
4. `inject_importmap_pins` - injects develoz-ui Stimulus controller pins into `config/importmap.rb` via `inject_once`

### Spec Coverage

17 tests covering:
- destination_root binding
- Gemfile: develoz_ui path in dev/test group, github in production group, idempotency
- .gitmodules: creation when absent, submodule section content, append to existing, idempotency
- Setup script: existence, executable bit, git submodule command, error documentation, idempotency, executable bit preserved on re-run
- Importmap: pin injection, existing content preservation, idempotency

### RuboCop Notes

- Long string literals with `\n` and `\t` escapes can exceed the 120-char line limit. Use Ruby string continuation (`\` at end of line) to split across multiple lines: `"[submodule ...]\n" \` followed by `"\tpath = ...\n" \`.


## DB Backup Generator (Task 31)

The db_backup generator creates a `bin/db-backup` shell script (pg_dump + gzip + retention pruning), a `lib/tasks/backup.rake` rake fallback, and optionally injects a `db-backup` compose service when `--docker` is present.

### Key Decisions

1. **Spec path follows existing convention (`spec/develoz/generators/`)**: The task referenced `spec/generators/db_backup_generator_spec.rb`, but all 19 existing generator specs live at `spec/develoz/generators/`. Placing the spec there keeps consistency and ensures the `RSpec/SpecFilePathFormat` cop passes. The task path was treated as shorthand.

2. **Compose service via template + ERB rendering**: The `compose_service.tt` template contains `<%= app_name %>` ERB. Since `inject_once` takes a raw content string (not a Thor template render), the generator reads the template file and renders it with `ERB.new(raw, trim_mode: "-").result(binding)`. The generator's binding provides `app_name` from the base helper. This keeps the service definition in a template file (as required) while still using `inject_once` for idempotent injection.

3. **`class_option :docker` with default false**: The install generator invokes sub-generators with `klass.new([], {}, destination_root: ...)` (empty options), so `options[:docker]` defaults to false in the install flow. When run standalone with `--docker`, the compose service is injected. This satisfies "Do NOT require docker" - the rake fallback is always created; compose injection is opt-in.

4. **`inject_once` with marker guard for compose**: The `marker:` parameter ("# db-backup service (develoz:db_backup)") provides idempotency independent of the full content block. The `after: /^services:\n/` anchor inserts the service right after the `services:` line, preserving existing services.

5. **bin/db-backup is a shell script (excluded from coverage)**: The spec_helper filters `/bin/` and `.sh` files from coverage. The rake task IS Ruby and gets coverage. The rake task uses `Open3.popen3` + `Zlib::GzipWriter` for the Ruby fallback path.

### Generator Methods

1. `create_backup_script` - templates `bin/db-backup` and chmods to 0o755
2. `create_backup_rake` - templates `lib/tasks/backup.rake`
3. `inject_compose_service` - returns early unless `options[:docker]`; injects compose service snippet via `inject_once` with marker guard
4. `ensure_backups_gitignored` - adds `/backups/` to `.gitignore` via `ensure_gitignore`

### Spec Coverage

22 tests covering:
- destination_root binding
- bin/db-backup: existence, executable bit, pg_dump+gzip, .sql.gz, retention pruning, idempotency, executable bit preserved on re-run
- rake task: existence, backup namespace with create+prune tasks, frozen_string_literal, retention env var, idempotency
- gitignore: /backups/ added, idempotency
- compose service: NOT injected when docker=false, NOT injected when docker unset, injected when docker=true, 6h schedule (21600s), retention env, depends_on postgres, preserves existing services, idempotency

### RuboCop Notes

- `Layout/TrailingEmptyLines: Final newline missing` appeared on both generated files after initial write. Fixed via `rubocop -A` autocorrect. Always verify files end with exactly one newline.
