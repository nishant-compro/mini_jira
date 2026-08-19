#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "pathname"

MAX_PATCH_BYTES = 2 * 1024 * 1024
MAX_BINARY_BYTES = 512 * 1024
PROTECTED = [
  %r{\A\.github/},
  %r{\A(?:.*/)?\.agents/},
  %r{\A(?:.*/)?\.claude/},
  %r{\A\.jira-agent/},
  %r{\A(?:.*/)?AGENTS(?:\.override)?\.md\z},
  %r{\A(?:.*/)?CLAUDE(?:\.local)?\.md\z},
  %r{\A\.gitignore\z},
  %r{\A(?:.*/)?\.env(?:\..*)?\z},
  %r{\A(?:.*/)?\.npmrc\z},
  %r{\A(?:.*/)?\.bundle/config\z},
  %r{\Abackend/config/credentials(?:\.yml\.enc)?\z},
  %r{\A(?:.*/)?(?:brakeman|rubocop|gitleaks)[^/]*\z}i,
  %r{\Asonar-project\.properties\z},
  %r{\A(?:.*/)?[^/]*(?:private[_-]?key|credentials|secrets?)[^/]*\z}i,
  %r{\A(?:.*/)?[^/]+\.(?:pem|p12|pfx|key)\z}i
].freeze

def fail_patch(message)
  warn "::error::Patch rejected: #{message}"
  exit 1
end

already_applied = ARGV.delete("--already-applied")
patch_path = ARGV.fetch(0)
fail_patch("received unexpected arguments") unless ARGV.length == 1
fail_patch("file does not exist") unless File.file?(patch_path)
fail_patch("patch is empty") if File.zero?(patch_path)
fail_patch("patch exceeds #{MAX_PATCH_BYTES} bytes") if File.size(patch_path) > MAX_PATCH_BYTES

patch = File.binread(patch_path)
fail_patch("creates, modifies, or deletes a symbolic link") if patch.match?(/^(?:(?:new|deleted) file mode|old mode|new mode) 120000$/)

stdout, stderr, status = Open3.capture3("git", "apply", "--numstat", "-z", patch_path)
fail_patch("cannot be parsed by git apply: #{stderr.strip}") unless status.success?

parts = stdout.split("\0")
entries = []
index = 0
while index < parts.length
  columns = parts[index].split("\t", 3)
  break if columns.length < 3

  if columns[2].empty?
    entries << { added: columns[0], deleted: columns[1], paths: [parts[index + 1], parts[index + 2]] }
    index += 3
  else
    entries << { added: columns[0], deleted: columns[1], paths: [columns[2]] }
    index += 1
  end
end
paths = entries.flat_map { |entry| entry.fetch(:paths) }.compact.uniq
fail_patch("contains no file changes") if paths.empty?

paths.each do |path|
  clean = Pathname.new(path).cleanpath.to_s
  fail_patch("uses an unsafe path #{path.inspect}") if path.start_with?("/") || clean == ".." || clean.start_with?("../") || clean != path
  fail_patch("changes protected path #{path}") if PROTECTED.any? { |pattern| pattern.match?(path) }
end

apply_arguments = [ "git", "apply", "--check", "--whitespace=error-all" ]
apply_arguments << "--reverse" if already_applied
apply_arguments << patch_path
_check_out, check_err, check_status = Open3.capture3(*apply_arguments)
state = already_applied ? "does not match the current working tree" : "does not apply cleanly"
fail_patch("#{state}: #{check_err.strip}") unless check_status.success?

binary_paths = entries.filter_map { |entry| entry.fetch(:paths).last if entry[:added] == "-" && entry[:deleted] == "-" }
binary_paths.each do |path|
  encoded = patch.scan(/^literal (\d+)$/).flatten.map(&:to_i).max.to_i
  fail_patch("binary #{path} exceeds #{MAX_BINARY_BYTES} bytes") if encoded > MAX_BINARY_BYTES
end

puts paths
