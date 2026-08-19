# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

class ValidatePatchTest < Minitest::Test
  SCRIPT = File.expand_path("validate_patch.rb", __dir__)

  def test_accepts_normal_source_patch
    in_repository do |repo|
      File.write(File.join(repo, "app.rb"), "puts :changed\n")

      assert_validator_accepts(repo)
    end
  end

  def test_rejects_protected_workflow_patch
    in_repository do |repo|
      FileUtils.mkdir_p(File.join(repo, ".github/workflows"))
      File.write(File.join(repo, ".github/workflows/unsafe.yml"), "on: push\n")

      assert_validator_rejects(repo, "protected path")
    end
  end

  def test_rejects_automation_scratch_path
    in_repository do |repo|
      FileUtils.mkdir_p(File.join(repo, ".jira-agent"))
      File.write(File.join(repo, ".jira-agent/task.md"), "private task context\n")

      assert_validator_rejects(repo, "protected path")
    end
  end

  def test_rejects_shared_agent_instructions
    in_repository do |repo|
      File.write(File.join(repo, "AGENTS.md"), "unsafe override\n")

      assert_validator_rejects(repo, "protected path")
    end
  end

  def test_rejects_nested_agent_override
    in_repository do |repo|
      FileUtils.mkdir_p(File.join(repo, "backend"))
      File.write(File.join(repo, "backend/AGENTS.override.md"), "unsafe override\n")

      assert_validator_rejects(repo, "protected path")
    end
  end

  def test_rejects_agent_skill_discovery_path
    in_repository do |repo|
      FileUtils.mkdir_p(File.join(repo, ".agents/skills/example"))
      File.write(File.join(repo, ".agents/skills/example/SKILL.md"), "unsafe override\n")

      assert_validator_rejects(repo, "protected path")
    end
  end

  def test_rejects_symlink_patch
    in_repository do |repo|
      File.symlink("app.rb", File.join(repo, "linked.rb"))

      assert_validator_rejects(repo, "symbolic link")
    end
  end

  def test_accepts_rename_between_safe_paths
    in_repository do |repo|
      FileUtils.mv(File.join(repo, "app.rb"), File.join(repo, "renamed.rb"))

      assert_validator_accepts(repo)
    end
  end

  def test_accepts_patch_that_is_already_present_in_working_tree
    in_repository do |repo|
      File.write(File.join(repo, "app.rb"), "puts :changed\n")
      patch = patch_for_working_tree(repo)

      _output, error, status = Open3.capture3("ruby", SCRIPT, "--already-applied", patch, chdir: repo)

      assert status.success?, error
    ensure
      FileUtils.rm_f(patch) if patch
    end
  end

  def test_accepts_already_applied_new_file
    in_repository do |repo|
      File.write(File.join(repo, "new.rb"), "puts :new\n")

      assert_validator_accepts_working_tree(repo)
    end
  end

  def test_accepts_already_applied_deleted_file
    in_repository do |repo|
      FileUtils.rm(File.join(repo, "app.rb"))

      assert_validator_accepts_working_tree(repo)
    end
  end

  private

  def in_repository
    Dir.mktmpdir("jira-agent-patch-test") do |repo|
      git!(repo, "init", "--quiet")
      git!(repo, "config", "user.name", "Test")
      git!(repo, "config", "user.email", "test@example.invalid")
      File.write(File.join(repo, "app.rb"), "puts :original\n")
      git!(repo, "add", "app.rb")
      git!(repo, "commit", "--quiet", "-m", "initial")
      yield repo
    end
  end

  def patch_for(repo)
    path = patch_for_working_tree(repo)
    git!(repo, "reset", "--hard", "HEAD")
    git!(repo, "clean", "-fd")
    path
  end

  def patch_for_working_tree(repo)
    git!(repo, "add", "--intent-to-add", "--all")
    patch, error, status = Open3.capture3("git", "diff", "--binary", "--full-index", "HEAD", chdir: repo)
    raise error unless status.success?

    path = File.join(Dir.tmpdir, "candidate-#{Process.pid}-#{rand(1_000_000)}.patch")
    File.binwrite(path, patch)
    path
  end

  def assert_validator_accepts(repo)
    patch = nil
    patch = patch_for(repo)
    _output, error, status = Open3.capture3("ruby", SCRIPT, patch, chdir: repo)
    assert status.success?, error
  ensure
    FileUtils.rm_f(patch) if patch
  end

  def assert_validator_accepts_working_tree(repo)
    patch = nil
    patch = patch_for_working_tree(repo)
    _output, error, status = Open3.capture3("ruby", SCRIPT, "--already-applied", patch, chdir: repo)
    assert status.success?, error
  ensure
    FileUtils.rm_f(patch) if patch
  end

  def assert_validator_rejects(repo, message)
    patch = nil
    patch = patch_for(repo)
    _output, error, status = Open3.capture3("ruby", SCRIPT, patch, chdir: repo)
    refute status.success?
    assert_includes error, message
  ensure
    FileUtils.rm_f(patch) if patch
  end

  def git!(repo, *arguments)
    _output, error, status = Open3.capture3("git", *arguments, chdir: repo)
    raise error unless status.success?
  end
end
