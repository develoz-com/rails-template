# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"
load File.expand_path("../../bin/update_changelog", __dir__)

RSpec.describe UpdateChangelog do
  let(:directory) { Dir.mktmpdir }
  let(:changelog_path) { File.join(directory, "CHANGELOG.md") }
  let(:repository) { "owner/project" }
  let(:script) { File.expand_path("../../bin/update_changelog", __dir__) }

  after { FileUtils.remove_entry(directory) }

  def changelog(unreleased: "### Added\n\n- A useful change.\n", repository: nil)
    repository ||= self.repository
    <<~CHANGELOG
      # Changelog

      ## [Unreleased]

      #{unreleased}
      ## [0.1.0] - 2026-07-15

      ### Added

      - Initial release.

      [Unreleased]: https://github.com/#{repository}/compare/v0.1.0...HEAD
      [0.1.0]: https://github.com/#{repository}/releases/tag/v0.1.0
    CHANGELOG
  end

  def run_update(*)
    Open3.capture3(
      RbConfig.ruby,
      script,
      "--tag", "v0.2.0",
      "--date", "2026-07-16",
      "--repository", repository,
      *,
      changelog_path
    )
  end

  def write_changelog(content = changelog)
    File.write(changelog_path, content)
  end

  it "promotes Unreleased content and updates canonical reference links" do
    write_changelog

    _stdout, stderr, status = run_update

    expect(status).to be_success
    expect(stderr).to be_empty
    expect(File.read(changelog_path)).to eq(released_changelog)
  end

  it "does not write in check mode" do
    write_changelog
    original = File.binread(changelog_path)

    _stdout, stderr, status = run_update("--check")

    expect(status).to be_success
    expect(stderr).to be_empty
    expect(File.binread(changelog_path)).to eq(original)
  end

  it "is byte-identical when the target release already exists validly" do
    write_changelog(released_changelog)
    original = File.binread(changelog_path)

    _stdout, stderr, status = run_update

    expect(status).to be_success
    expect(stderr).to be_empty
    expect(File.binread(changelog_path)).to eq(original)
  end

  it "is byte-identical when an existing target has a different date" do
    write_changelog(released_changelog.sub("2026-07-16", "2026-07-14"))
    original = File.binread(changelog_path)

    _stdout, stderr, status = run_update

    expect(status).to be_success
    expect(stderr).to be_empty
    expect(File.binread(changelog_path)).to eq(original)
  end

  it "rejects an existing target below a newer release" do
    write_changelog(released_changelog)
    original = File.binread(changelog_path)

    _stdout, stderr, status = run_update("--tag", "v0.1.0")

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: existing target 0.1.0 is not the newest release (0.2.0)\n")
    expect(File.binread(changelog_path)).to eq(original)
  end

  it "rejects nonblank Unreleased content above an existing target" do
    content = released_changelog.sub("## [Unreleased]\n\n", "## [Unreleased]\n\n### Added\n\n- Later work.\n\n")
    write_changelog(content)
    original = File.binread(changelog_path)

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: Unreleased section must be blank when target 0.2.0 already exists\n")
    expect(File.binread(changelog_path)).to eq(original)
  end

  it "requires exactly one Unreleased heading" do
    write_changelog(changelog.sub("## [0.1.0]", "## [Unreleased]\n\n## [0.1.0]"))

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: expected exactly one '## [Unreleased]' heading, found 2\n")
  end

  it "requires nonblank Unreleased content for a new release" do
    write_changelog(changelog(unreleased: ""))

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: Unreleased section is blank\n")
  end

  it "rejects a noncanonical Unreleased reference" do
    write_changelog(changelog.sub("compare/v0.1.0...HEAD", "compare/v9.9.9...HEAD"))

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to include("noncanonical [Unreleased] reference")
  end

  it "rejects a release reference for another repository" do
    invalid = changelog.sub(
      "https://github.com/#{repository}/releases/tag/v0.1.0",
      "https://github.com/other/project/releases/tag/v0.1.0"
    )
    write_changelog(invalid)

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to include("noncanonical [0.1.0] reference")
  end

  it "rejects duplicate version headings" do
    duplicate = changelog.sub("## [0.1.0] - 2026-07-15", "## [0.1.0] - 2026-07-15\n\n## [0.1.0] - 2026-07-15")
    write_changelog(duplicate)

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: duplicate release heading for 0.1.0\n")
  end

  it "accepts only stable vX.Y.Z tags" do
    write_changelog

    _stdout, stderr, status = run_update("--tag", "0.2.0")

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: --tag must match vX.Y.Z\n")
  end

  it "accepts only real ISO dates" do
    write_changelog

    _stdout, stderr, status = run_update("--date", "2026-02-30")

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: --date must be a valid YYYY-MM-DD date\n")
  end

  it "requires an owner/repository slug" do
    write_changelog

    _stdout, stderr, status = run_update("--repository", "owner")

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: --repository must match owner/repository\n")
  end

  it "requires exactly one changelog path" do
    _stdout, stderr, status = Open3.capture3(RbConfig.ruby, script, "--tag", "v0.2.0")

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: missing argument: CHANGELOG.md\n")
  end

  it "reports an unreadable changelog path" do
    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: changelog does not exist: #{changelog_path}\n")
  end

  it "requires every named option" do
    write_changelog
    _stdout, stderr, status = Open3.capture3(RbConfig.ruby, script, changelog_path)

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: missing required option: --tag\n")
  end

  it "rejects invalid historical release dates" do
    write_changelog(changelog.sub("2026-07-15", "2026-02-30"))

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: release 0.1.0 date must be a valid YYYY-MM-DD date\n")
  end

  it "rejects version-looking release headings with malformed date text" do
    write_changelog(changelog.sub("## [0.1.0] - 2026-07-15", "## [0.1.0] - TBD"))

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: malformed release heading: ## [0.1.0] - TBD\n")
  end

  it "rejects release headings outside newest-to-oldest semantic order" do
    out_of_order = released_changelog.gsub("0.2.0", "1.9.0").gsub("0.1.0", "1.10.0")
    write_changelog(out_of_order)

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: release 1.10.0 must be older than 1.9.0\n")
  end

  it "requires a prior release for a comparison link" do
    content = changelog.gsub(/^## \[0\.1\.0\].*\n(?:.|\n)*?\n(?=\[Unreleased\]:)/, "")
    write_changelog(content.sub("compare/v0.1.0...HEAD", "compare/v0.0.0...HEAD"))

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: expected at least one release heading\n")
  end

  it "rejects duplicate canonical references" do
    duplicate = changelog.sub("[0.1.0]:", "[0.1.0]: https://github.com/#{repository}/releases/tag/v0.1.0\n[0.1.0]:")
    write_changelog(duplicate)

    _stdout, stderr, status = run_update

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: duplicate [0.1.0] reference\n")
  end

  it "requires a new target version to be newer than the latest release" do
    write_changelog

    _stdout, stderr, status = run_update("--tag", "v0.0.9")

    expect(status).not_to be_success
    expect(stderr).to eq("update_changelog: target version 0.0.9 must be newer than 0.1.0\n")
  end

  it "is executable" do
    expect(File.stat(script).mode & 0o111).to be_positive
  end

  def released_changelog
    <<~CHANGELOG
      # Changelog

      ## [Unreleased]

      ## [0.2.0] - 2026-07-16

      ### Added

      - A useful change.

      ## [0.1.0] - 2026-07-15

      ### Added

      - Initial release.

      [Unreleased]: https://github.com/#{repository}/compare/v0.2.0...HEAD
      [0.2.0]: https://github.com/#{repository}/compare/v0.1.0...v0.2.0
      [0.1.0]: https://github.com/#{repository}/releases/tag/v0.1.0
    CHANGELOG
  end
end
