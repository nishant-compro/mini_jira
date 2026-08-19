#!/usr/bin/env ruby
# frozen_string_literal: true

paths = ARGF.each_line.map(&:strip).reject(&:empty?)
backend = paths.any? { |path| path.start_with?("backend/") }
frontend = paths.any? { |path| path.start_with?("frontend/") }
shared = paths.any? do |path|
  !path.start_with?("backend/", "frontend/", "docs/") &&
    !path.match?(/\A(?:README|PLAN|CHANGELOG|LICENSE)(?:\..*)?\z/i)
end
backend ||= shared
frontend ||= shared

output = ENV["GITHUB_OUTPUT"]
if output && !output.empty?
  File.open(output, "a") do |file|
    file.puts("backend=#{backend}")
    file.puts("frontend=#{frontend}")
  end
else
  puts "backend=#{backend}"
  puts "frontend=#{frontend}"
end
