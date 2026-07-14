# frozen_string_literal: true

RSpec::Matchers.define :match_canonical do |fixture_path|
  match do |actual|
    @expected = File.read(fixture_path)
    actual == @expected
  end

  failure_message do |actual|
    expected_lines = @expected.lines
    actual_lines = actual.lines

    diff = []
    diff << "Expected content from #{fixture_path}:"
    diff << ""

    max_lines = [expected_lines.length, actual_lines.length].max
    (0...max_lines).each do |i|
      expected_line = expected_lines[i] || ""
      actual_line = actual_lines[i] || ""

      next if expected_line == actual_line

      diff << "Line #{i + 1}:"
      diff << "  Expected: #{expected_line.inspect}"
      diff << "  Actual:   #{actual_line.inspect}"
    end

    diff.join("\n")
  end

  description do
    "match canonical content from #{fixture_path}"
  end
end
