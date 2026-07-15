# Develoz Rails

Develoz Rails is an opinionated application generator for Rails 8.1. It wraps
`rails new` with a tested Develoz baseline and lets each application opt into
product, deployment, and operations features as needed.

The generated baseline includes PostgreSQL, RSpec, the Solid stack, shared
model concerns, strict loading, maintenance tasks, frontend conventions,
documentation tooling, CI configuration, and application versioning.

## Quickstart

Install the gem and generate an application:

```bash
gem install develoz-rails
develoz new my_app
```

The interactive flow asks which optional features to include. For an
unattended run, pass `--yes`; omitted opt-in features remain disabled:

```bash
develoz new my_app --yes --auth --ui --docker
```

Use `--ruby=VERSION` or `--rails=VERSION` to select explicit toolchain
versions. Run `develoz help new` for the complete command reference.

For prerequisites and detailed setup, see the
[installation guide](docs/guide/installation.md).

## Feature matrix

Core features are installed in every generated application.

| Mode | Feature | Switch | What it adds |
| --- | --- | --- | --- |
| Core | Tooling | Always on | Editor settings, environment files, and shared application constants |
| Core | Testing | Always on | RSpec, FactoryBot, Capybara, Selenium, parallel tests, and coverage |
| Core | Solid stack | Always on | Solid Queue, Solid Cache, Solid Cable, and Mission Control Jobs |
| Core | CI and quality | Always on | CI workflow plus Ruby, security, frontend, and documentation checks |
| Core | Database | Always on | PostgreSQL configuration and `pg_search` |
| Core | Shared concerns | Always on | Search, optimized finder, transition, and configuration concerns |
| Core | Strict loading | Always on | Strict loading by default for Active Record models |
| Core | Maintenance | Always on | Maintenance Tasks integration and task examples |
| Core | Frontend | Always on | Importmap, Hotwire, AnnotateRb, and Pagy; use `--skip-pagy` to omit Pagy |
| Core | Documentation renderer | Always on | Markdown documentation model, controller, view, assets, and route |
| Core | Documentation specs | Always on | Documentation generation, checks, screenshots, and an example system spec |
| Core | Agent documentation | Always on | `AGENTS.md`, development guides, PR template, and external API test support |
| Core | Versioning | Always on | Application version constant, helper, and display partial |
| Opt-in | REST API | `--api` | Blueprinter, RSwag, API base controller, routes, and request spec |
| Opt-in | Authentication | `--auth` | Native Rails authentication models, controllers, views, routes, and specs |
| Opt-in | Progressive Web App | `--pwa` | Web manifest, service worker, offline page, registration, and routes |
| Opt-in | Push notifications | `--push` | Web Push subscriptions and notification support; also enables PWA support |
| Opt-in | Active Resource | `--active-resource` | Active Resource dependency and application resource classes |
| Opt-in | Admin | `--admin` | Admin base controller, layout, dashboard, and routes |
| Opt-in | Develoz UI | `--ui` | Develoz UI integration and controller pins |
| Opt-in | Kamal | `--kamal` | Kamal deployment configuration, secrets, and production Dockerfile |
| Opt-in | Docker | `--docker` | Local Docker Compose workflow, development image, and helper scripts |
| Opt-in | Database backups | `--db-backup` | Backup script, rake task, retention settings, and backup ignore rules |

## Project documentation

- [Installation guide](docs/guide/installation.md)
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)
