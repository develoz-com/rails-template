# Installation and usage

One command applies 13 core generators, while 10 opt-in flags let you add only
the product features you need. How do we get that payoff without guessing which
defaults, prerequisites, or follow-up steps are hidden behind the command?

By the end of this guide, you will be able to:

- install and verify the `develoz-rails` gem;
- create a new application interactively or with reproducible flags;
- adopt Develoz generators one feature at a time in an existing Rails app; and
- initialize `develoz-ui` and diagnose the most common setup failures.

## Prerequisites

Develoz Rails requires:

- Ruby 3.4 or newer;
- Rails 8.1 (`railties ~> 8.1`);
- Git; and
- PostgreSQL 18 or newer for the generated database configuration.

Use one Ruby and tool-version manager consistently. Generated applications use
`.tool-versions`, which works directly with asdf and can also be consumed by
mise. The generator records runtime versions; it does not install or activate
them for the current shell.

Before continuing, check the executables that will do the work:

```bash
ruby --version
rails --version
git --version
psql --version
```

## Install the gem

Install the command-line executable into the currently active Ruby:

```bash
gem install develoz-rails
```

Then verify the installation:

```bash
develoz version
develoz help new
```

If `develoz` is not found, the gem was usually installed under a different Ruby
or its executable directory is not on `PATH`. See [Troubleshooting](#troubleshooting).

## Understand what `develoz new` does

The command has two stages:

1. It runs `rails new APP_NAME --skip-test --skip-ci --skip-bundle`.
2. It applies the Develoz core generators and any selected opt-in generators.

Rails' default test and CI files are skipped because Develoz installs its own
RSpec and CI setup. Bundling is also skipped, so run `bundle install` after you
have reviewed the generated `Gemfile` and initialized any selected submodules.

The core installation always includes tooling, RSpec, Solid Queue/Cache/Cable,
CI, PostgreSQL configuration, shared concerns, strict loading, maintenance
tasks, frontend foundations, documentation support, agent documentation, and
application versioning. Pagy is part of frontend core unless you opt out.

Every product feature is opt-in. In particular, `--yes` means "accept the
defaults without prompting"; it does not turn every feature on.

## Create a new application interactively

Start with only an application name:

```bash
develoz new dispatch
```

The CLI asks, in order, whether to include:

1. API layer
2. authentication
3. PWA support
4. push notifications
5. ActiveResource
6. admin dashboard
7. develoz-ui
8. Kamal deployment
9. Docker setup
10. database backups

Answer `y` or `n` to each prompt. You can preselect one feature and continue
interactively for the rest:

```bash
develoz new dispatch --auth
```

Here, authentication is already selected, so the CLI does not ask its prompt.

## Create a new application from flags

For a repeatable core-only application, use:

```bash
develoz new dispatch --yes
```

Unspecified opt-in features remain disabled. To build an API application with
authentication and no remaining prompts, make both choices explicit:

```bash
develoz new dispatch --api --auth --yes
```

A fully selected example looks like this:

```bash
develoz new dispatch \
  --api \
  --auth \
  --pwa \
  --push \
  --active-resource \
  --admin \
  --ui \
  --kamal \
  --docker \
  --db-backup \
  --ruby 4.0.5 \
  --rails 8.1 \
  --yes
```

`--push` also selects PWA support, so `--pwa` is redundant in that example. It
is shown because an explicit feature list is easier to audit in scripts.

### Finish the generated application

Move into the application and install the recorded tools and gems:

```bash
cd dispatch
asdf install
bundle install
```

With mise, replace `asdf install` with:

```bash
mise install
```

If you selected `--ui`, initialize that submodule before `bundle install`:

```bash
bin/setup_develoz_ui
bundle install
```

Before running migrations, inspect the generated files in `db/migrate`. Some
feature generators create reusable migration templates without timestamped
filenames. Give each one a unique Rails migration timestamp. The core
`add_status_transitions` template also uses a placeholder `:records` table;
replace it with the table that will include `Transitionable`.

After adapting those app-specific migrations and configuring PostgreSQL, run:

```bash
bin/rails db:prepare
bin/ci
```

## Full flag reference

All flags below belong to `develoz new APP_NAME`.

| Flag | Type | Default | Effect |
| --- | --- | --- | --- |
| `--api` | Opt-in | Off | Adds a versioned REST API foundation with Blueprinter and RSwag. |
| `--auth` | Opt-in | Off | Adds bcrypt-based users, sessions, password resets, routes, and request specs. |
| `--pwa` | Opt-in | Off | Adds the manifest, service worker, offline page, registration JavaScript, and routes. |
| `--push` | Opt-in | Off | Adds web push subscriptions, a delivery service, browser code, and VAPID environment keys. PWA is enabled automatically. |
| `--active-resource` | Opt-in | Off | Adds the `activeresource` gem plus application and example resource models. |
| `--admin` | Opt-in | Off | Adds an admin namespace, base/dashboard controllers, layout, view, and root route. |
| `--ui` | Opt-in | Off | Wires the private `develoz-ui` repository as a submodule and gem, plus Importmap pins. |
| `--kamal` | Opt-in | Off | Adds Kamal, production deployment files, secrets configuration, and a PostgreSQL accessory. |
| `--docker` | Opt-in | Off | Adds the development Docker Compose stack, development image, scripts, and environment keys. |
| `--db-backup` | Opt-in | Off | Adds the database backup executable, Rake task, and backup ignore rule. |
| `--skip-pagy` | Opt-out | Off | Requests frontend core without the Pagy gem and initializer. Pagy is otherwise included. |
| `--ruby VERSION` | Override | Latest resolved version | Uses `VERSION` for `.tool-versions` and `.ruby-version`. It does not switch the Ruby running the command. |
| `--rails VERSION` | Override | Latest resolved version | Supplies `VERSION` to Rails version resolution. The `rails` executable already on `PATH` still performs `rails new`. |
| `--yes` | Execution | Off | Suppresses feature prompts and leaves every unspecified opt-in feature disabled. |

When version lookup is unavailable, the resolver falls back to Ruby `4.0.5`
and Rails `8.1`. The generated `.tool-versions` also records Node.js `24.15.0`
and PostgreSQL `18`.

Thor also exposes `--no-FLAG` and `--skip-FLAG` aliases for boolean options.
Those aliases explicitly decline one prompt. The dedicated `--skip-pagy` flag
is the supported product-level opt-out for Pagy.

## Feature matrix

### Always-on core

| Generator | What it adds |
| --- | --- |
| `develoz:tooling` | VS Code settings, `.env` files, constants initializer, and `dotenv-rails`. |
| `develoz:testing` | RSpec, Capybara, Selenium, SimpleCov, parallel tests, FactoryBot, and their configuration. |
| `develoz:solid` | Solid Queue, Solid Cache, Solid Cable, recurring jobs, Mission Control Jobs, and `/jobs`. |
| `develoz:ci` | `bin/ci`, GitHub Actions, Ruby/security/code-quality gems, and linter configuration. |
| `develoz:database` | PostgreSQL and `pg_search`, multi-database configuration, and the PostgreSQL 18 tool pin. |
| `develoz:concerns` | Searchable, optimized finder, transition, and configuration concerns with migrations and specs. |
| `develoz:strict_loading` | Strict-loading Active Record configuration. |
| `develoz:maintenance` | Maintenance Tasks, `/maintenance_tasks`, an example task, and maintenance Rake tasks. |
| `develoz:frontend_core` | Importmap, AnnotateRb, and Pagy by default. |
| `develoz:docs_render` | Markdown rendering with Redcarpet, Rouge, Mermaid JavaScript, views, styles, and `/docs`. |
| `develoz:doc_specs` | Screenshot-backed documentation specs, `bin/generate-docs`, and `docs:check`. |
| `develoz:agents_docs` | `AGENTS.md`, development/testing/performance docs, PR template, Faraday, VCR, and WebMock examples. |
| `develoz:versioning` | `APP_VERSION`, an `app_version` helper, and a shared version partial. |

### Opt-in features

| Flag | Existing-app generator | Main output | Important relationship |
| --- | --- | --- | --- |
| `--api` | `develoz:api` | Blueprinter, RSwag, `/api-docs`, API v1 base controller, blueprint, and request spec. | Uses Pagy support from frontend core unless the app supplies an alternative. |
| `--auth` | `develoz:auth` | User/current models, authentication concern, session/password flows, mailer, migration, and specs. | No other opt-in flag is required. |
| `--pwa` | `develoz:pwa` | Manifest, service worker, offline page, registration code, and routes. | Required by push. |
| `--push` | `develoz:push` | `web-push`, subscription model/migration, notification service, browser handlers, and VAPID keys. | Automatically installs PWA output when invoked directly without `--pwa`. |
| `--active-resource` | `develoz:active_resource` | ActiveResource base and example models. | No other opt-in flag is required. |
| `--admin` | `develoz:admin` | Admin controllers, layout, dashboard, and namespace route. | Direct generator accepts `--ui` to render its UI-aware template variant. |
| `--ui` | `develoz:ui` | Local UI submodule for development/test, GitHub gem for production, setup script, and Importmap pins. | Run frontend core first. Requires repository access. |
| `--kamal` | `develoz:kamal` | Deploy configuration, production Dockerfile, secrets file, and PostgreSQL accessory. | Direct generator accepts `--push` for its push-aware template variant. |
| `--docker` | `develoz:docker` | Compose stack, development Dockerfile, setup/run scripts, and service environment keys. | Run tooling first so `.env` files exist. |
| `--db-backup` | `develoz:db_backup` | Backup script, Rake task, and ignored backup directory. | Run after Docker and pass `--docker` to inject the optional Compose service. |

## Adopt Develoz in an existing Rails app

Use the application bundle for generators so the command runs against the same
Ruby and Rails versions as the app:

```bash
bundle add develoz-rails --group=development
```

Commit or otherwise back up the current app first. Generators are designed to
avoid duplicate gem, route, and environment entries, but they also create and
adapt real application files. Review each change before moving to the next
generator.

### Apply the complete core baseline

From the Rails application root:

```bash
bin/rails generate develoz:install
```

Add the same opt-in flags used by `develoz new` when you want optional features:

```bash
bin/rails generate develoz:install --api --auth --ui
```

`rails g` is the short form of `rails generate`, so the equivalent command is:

```bash
rails g develoz:install --api --auth --ui
```

The installer preserves the manifest order. That makes it the safest choice
when adopting the complete baseline.

### Apply core generators individually

Run only the slices the app needs, in this order when selecting several:

```bash
rails g develoz:tooling
rails g develoz:testing
rails g develoz:solid
rails g develoz:ci
rails g develoz:database
rails g develoz:concerns
rails g develoz:strict_loading
rails g develoz:maintenance
rails g develoz:frontend_core
rails g develoz:docs_render
rails g develoz:doc_specs
rails g develoz:agents_docs
rails g develoz:versioning
```

To omit Pagy during incremental adoption, use:

```bash
rails g develoz:frontend_core --skip-pagy
```

### Add one optional feature

Each flag maps to a generator that can be run independently:

```bash
rails g develoz:api
rails g develoz:auth
rails g develoz:pwa
rails g develoz:push
rails g develoz:active_resource
rails g develoz:admin
rails g develoz:ui
rails g develoz:kamal
rails g develoz:docker
rails g develoz:db_backup
```

Respect these ordering rules:

- Run `develoz:tooling` before versioning, push, or Docker so constants and
  environment files exist.
- Run `develoz:frontend_core` before `develoz:ui` so `config/importmap.rb`
  exists.
- `develoz:push` installs the PWA prerequisite automatically when needed.
- Run `develoz:docker` before `develoz:db_backup --docker` if you want the
  backup service inserted into `docker-compose.yml`.

For example, to add the UI and an admin dashboard that uses its template
variant:

```bash
rails g develoz:frontend_core
rails g develoz:ui
rails g develoz:admin --ui
bin/setup_develoz_ui
bundle install
```

After any generator changes the `Gemfile`, run `bundle install`. Review and
timestamp generated migration templates before running `bin/rails db:migrate`.

## Set up the develoz-ui submodule

The UI generator deliberately uses two sources:

- development and test load `develoz_ui` from `vendor/develoz-ui`; and
- production loads `develoz_ui` from `develoz-com/develoz-ui` on GitHub.

The generated `.gitmodules` entry uses the SSH URL
`git@github.com:develoz-com/develoz-ui.git`.

### Check UI prerequisites

You need:

1. **asdf or mise.** The app records Ruby, Node.js, and PostgreSQL in
   `.tool-versions`.
2. **PostgreSQL 18+.** The database config, Docker stack, and deployment
   accessory target PostgreSQL 18.
3. **GitHub access.** Your account and SSH key must be able to read the private
   `develoz-com/develoz-ui` repository. The `gh` CLI is a practical way to
   confirm account-level access; Git still uses SSH for the submodule.

Check access before running Bundler:

```bash
gh auth status
gh repo view develoz-com/develoz-ui
ssh -T git@github.com
```

Install the recorded runtimes with one tool manager:

```bash
asdf install
```

or:

```bash
mise install
```

### Initialize the submodule

From the generated app root, run:

```bash
bin/setup_develoz_ui
```

The script executes:

```bash
git submodule update --init --recursive vendor/develoz-ui
```

It exits with an error if `vendor/develoz-ui` is missing or empty. Once the
script succeeds, install the bundle:

```bash
bundle install
```

For a fresh clone of an app that already contains the UI integration, either
clone recursively or run the setup script after cloning:

```bash
git clone --recurse-submodules REPOSITORY_URL
```

or:

```bash
git clone REPOSITORY_URL
cd APP_DIRECTORY
bin/setup_develoz_ui
```

Production builds also need credentials that let Bundler fetch the private
GitHub gem source.

## Troubleshooting

### `develoz: command not found`

Confirm that the active Ruby owns the installed gem:

```bash
ruby -v
gem environment home
gem list develoz-rails
ruby -S develoz version
```

Activate the intended asdf or mise Ruby, reinstall the gem, and ensure that
Ruby's gem executable directory is on `PATH`.

### `rails new` fails

The CLI delegates application creation to the `rails` executable on `PATH`.
Check it directly:

```bash
which rails
rails --version
rails new scratch_app --skip-test --skip-ci --skip-bundle
```

Remove the scratch app after the check. `--ruby` records the selected Ruby in
the generated version files. `--rails` supplies a version to the resolver, but
the CLI still uses the Rails executable already on `PATH`. Neither flag switches
the current shell's executables.

### A non-interactive build is prompting

Add `--yes`. Feature flags select only the named features; without `--yes`, the
CLI still asks about every unspecified opt-in feature.

### `--yes` produced only the core stack

That is the intended default. List every desired feature before `--yes`, for
example:

```bash
develoz new dispatch --api --auth --docker --yes
```

### Pagy appeared after `--skip-pagy`

The direct frontend generator applies the opt-out itself:

```bash
rails g develoz:frontend_core --skip-pagy
```

The top-level installer currently accepts `--skip-pagy` but does not forward
sub-generator options to frontend core. For a new app, remove the `pagy` Gemfile
entry and `config/initializers/pagy.rb` before bundling. For an existing app,
prefer the direct command above when Pagy must be excluded.

### Rails cannot find `develoz:*` generators

Make the gem part of the existing application's bundle and use its Rails
executable:

```bash
bundle add develoz-rails --group=development
bundle install
bin/rails generate develoz:install --help
```

Run the command from the app root, where `Gemfile` and `config/routes.rb` exist.

### The UI submodule is empty or Bundler cannot find `develoz_ui`

First verify both repository and SSH access, then retry setup:

```bash
gh repo view develoz-com/develoz-ui
ssh -T git@github.com
bin/setup_develoz_ui
```

Do not run `bundle install` before the local submodule exists in development or
test, because the Gemfile points to `vendor/develoz-ui` in those environments.

### The UI generator did not add Importmap pins

The UI generator injects pins into an existing `config/importmap.rb`. Install
frontend core first, then rerun the idempotent UI generator:

```bash
rails g develoz:frontend_core
rails g develoz:ui
```

### PostgreSQL cannot connect or reports an incompatible version

Confirm PostgreSQL 18 is active:

```bash
psql --version
asdf current postgres
```

With mise, use `mise current` instead of `asdf current postgres`. Then verify
the app's `DATABASE_URL` or the connection values in `config/database.yml`
before running `bin/rails db:prepare`.

If you selected Docker, the generated Compose stack uses PostgreSQL 18 and the
default development credentials from `.env`:

```bash
docker compose up --build -d
docker compose logs -f postgres
```

### Migrations are missing or reference `records`

The generators provide reusable migration templates. Prefix generated migration
filenames with unique Rails timestamps so Rails discovers them. Replace the
`:records` placeholder in `add_status_transitions` with your model's table name
before migrating.

### Push was selected without PWA

No manual repair is needed. The manifest enables PWA whenever push is selected,
and the direct `develoz:push` generator also installs its PWA prerequisite.

### The backup service is absent from Docker Compose

The backup script and Rake task do not require Docker. To add the optional
Compose service during existing-app adoption, run Docker first and pass the
dependency explicitly:

```bash
rails g develoz:docker
rails g develoz:db_backup --docker
```

## In summary

Install `develoz-rails`, use interactive prompts for exploration, and use
explicit flags plus `--yes` for reproducible builds. The core baseline is always
installed; product features remain opt-in, with PWA automatically following
push and Pagy included by default. Existing apps are safest with
`develoz:install`, while individual generators give finer control when you
preserve their dependency order. For `develoz-ui`, verify PostgreSQL 18,
asdf/mise, and GitHub SSH access before initializing the submodule and running
Bundler.
