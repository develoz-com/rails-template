# Contributing

Contributions should preserve the generator's two main guarantees: a fresh
application is reproducible, and generated files remain faithful to their
canonical sources.

## Development setup

The repository uses [asdf](https://asdf-vm.com/) and pins Ruby 4.0.5 and
Node.js 24.15.0 in `.tool-versions`.

From the repository root:

```bash
asdf install
ruby --version
bundle install
```

The Ruby version output should start with `ruby 4.0.5`. `bin/setup` is also
available as a wrapper around `bundle install`.

Run a focused spec while developing, then run the complete checks before
submitting a change:

```bash
bundle exec rspec spec/path/to/spec.rb
./bin/ci
```

`./bin/ci` runs the full RSpec suite followed by RuboCop and exits on the first
failure. RSpec also enforces 100% line and branch coverage through SimpleCov,
so the coverage gate is part of every full CI run.

## Canonical fixtures

Canonical fixtures are byte-for-byte copies of files from source repositories.
Templates may adapt those files with documented substitutions, while fidelity
specs compare rendered output with the committed fixture using
`match_canonical`.

To refresh the configured sources:

```bash
bundle exec rake develoz:fetch_canonical
```

Private sources require authentication through `GH_TOKEN` or `gh auth token`.
The complete source-to-template map is in
`templates/CANONICAL_SOURCES.md`.

When adding or updating a canonical template:

1. Add or update its source mapping in `lib/tasks/canonical.rake`.
2. Run `bundle exec rake develoz:fetch_canonical` rather than editing the
   downloaded fixture by hand.
3. Store the source under `spec/fixtures/canonical/<owner>-<repo>/`.
4. Add the `.tt` template and record any substitutions in
   `templates/CANONICAL_SOURCES.md`.
5. Add or update a spec in `spec/fidelity/` that uses `match_canonical`.
6. Run `./bin/ci` and include the refreshed fixture with the change.

## Adding a generator

Use an existing generator with similar behavior as the starting point. A
generator named `example` follows this layout:

```text
lib/generators/develoz/example/
  example_generator.rb
  templates/
```

The class must be named `Develoz::Generators::ExampleGenerator`, inherit from
`Develoz::Generators::Base`, and set its `source_root` to the adjacent
`templates` directory. Generator lifecycle methods are public; implementation
helpers are private. Use the base class helpers for idempotent Gemfile, route,
environment, and file changes.

To register and verify a new generator:

1. Add its implementation and `.tt` templates under
   `lib/generators/develoz/<name>/`.
2. Register it in `config/generators.yml` with `always: true` for core behavior
   or a `requires` list for opt-in behavior.
3. For an opt-in generator, add the option to `Develoz::CLI::OPT_IN_FLAGS`,
   `Develoz::CLI::FLAG_LABELS`, the Thor options, and the install generator's
   class options and `OPTION_FLAGS`.
4. Add a focused spec at
   `spec/develoz/generators/<name>_generator_spec.rb`, including idempotency
   coverage where the generator changes existing files.
5. Extend `spec/develoz/generators/install_generator_spec.rb` and
   `spec/e2e/greenfield_spec.rb` when the manifest or public CLI behavior
   changes.
6. Add canonical fixture and fidelity coverage when templates derive from an
   external source.
7. Run `./bin/ci`.

## Release process

One-time setup uses RubyGems trusted publishing, so no token secret is needed:

1. Create a GitHub environment named `rubygems` with no secrets.
2. Add a pending trusted publisher for the `develoz-rails` gem on RubyGems with
   owner `develoz-com`, repository `rails-template`, workflow `release.yml`, and
   environment `rubygems`.

For each release:

1. Bump the version in `lib/develoz/version.rb` and add the user-facing changes
   to the `Unreleased` section of `CHANGELOG.md`.
2. Merge the changes and ensure CI is green.
3. Publish a stable GitHub Release with tag `vX.Y.Z` at the current `main`
   commit. Keep `main` unchanged until the release workflow finishes.
4. Let the workflow validate the release, publish the gem, and finalize and
   commit `CHANGELOG.md` to `main`.

Prereleases aren't supported. Never move or recreate a published tag. If gem
publication succeeds but changelog finalization fails, rerun the same failed
workflow rather than creating another release.
