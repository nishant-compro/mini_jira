#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module ReviewResponse
  class Error < StandardError; end

  module_function

  def required_env(name)
    value = ENV.fetch(name, "").strip
    raise Error, "#{name} is required" if value.empty?

    value
  end

  def api_request(method, path, token, body: nil)
    uri = URI("https://api.github.com/#{path.sub(%r{\A/}, "")}")
    request = Net::HTTP.const_get(method.capitalize).new(uri)
    request["Accept"] = "application/vnd.github+json"
    request["Authorization"] = "Bearer #{token}"
    request["X-GitHub-Api-Version"] = "2022-11-28"
    request["Content-Type"] = "application/json" if body
    request.body = JSON.generate(body) if body
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 30) do |http|
      http.request(request)
    end
    raise Error, "GitHub API #{method.upcase} #{path} returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response.body.empty? ? nil : JSON.parse(response.body)
  rescue JSON::ParserError
    raise Error, "GitHub API returned invalid JSON"
  end

  def response_status(published:, agent_outcome:, agent_output:)
    return :addressed if published == "true"
    return :blocked if agent_outcome == "success" && blocked_output?(agent_output)

    :failed
  end

  def blocked_output?(agent_output)
    summary = JSON.parse(agent_output).fetch("summary", "")
    summary.is_a?(String) && summary.start_with?("Blocked:")
  rescue JSON::ParserError, TypeError
    false
  end

  def status_text(status, commit_sha: nil)
    case status
    when :addressed
      "Requested changes were addressed in commit `#{commit_sha[0, 12]}`."
    when :blocked
      "The agent did not publish a revision because the requested change could not be applied under the repository safeguards."
    else
      "The agent workflow did not complete a revision."
    end
  end

  def marker(review_id, comment_id = nil)
    suffix = comment_id ? ":comment:#{comment_id}" : ":summary"
    "<!-- jira-agent-review-response:v1:#{review_id}#{suffix} -->"
  end

  def app_login(slug)
    "#{slug}[bot]"
  end

  def find_existing(comments, login, response_marker)
    comments.find do |comment|
      comment.dig("user", "login") == login && comment.fetch("body", "").include?(response_marker)
    end
  end

  def upsert_issue_comment(repo:, pr_number:, token:, login:, response_marker:, body:)
    comments = api_request("get", "repos/#{repo}/issues/#{pr_number}/comments?per_page=100", token)
    existing = find_existing(comments, login, response_marker)
    if existing
      api_request("patch", "repos/#{repo}/issues/comments/#{existing.fetch("id")}", token, body: { body: body })
    else
      api_request("post", "repos/#{repo}/issues/#{pr_number}/comments", token, body: { body: body })
    end
  end

  def upsert_inline_reply(repo:, pr_number:, comment_id:, token:, login:, response_marker:, body:)
    replies = api_request("get", "repos/#{repo}/pulls/#{pr_number}/comments?per_page=100", token).select do |comment|
      comment["in_reply_to_id"].to_i == comment_id
    end
    existing = find_existing(replies, login, response_marker)
    if existing
      api_request("patch", "repos/#{repo}/pulls/comments/#{existing.fetch("id")}", token, body: { body: body })
    else
      api_request("post", "repos/#{repo}/pulls/#{pr_number}/comments/#{comment_id}/replies", token, body: { body: body })
    end
  end

  def run
    token = required_env("GITHUB_TOKEN")
    repo = required_env("GITHUB_REPOSITORY")
    app_slug = required_env("APP_SLUG")
    metadata = JSON.parse(File.read(required_env("REVIEW_METADATA_PATH")))
    review_id = metadata.fetch("review_id").to_i
    pr_number = metadata.fetch("pr_number").to_i
    raise Error, "Review metadata contains an invalid review ID" unless review_id.positive?
    raise Error, "Review metadata contains an invalid pull request number" unless pr_number.positive?

    inline_comment_ids = metadata.fetch("inline_comment_ids", []).map(&:to_i).select(&:positive?).uniq
    status = response_status(
      published: ENV.fetch("REVISION_PUBLISHED", ""),
      agent_outcome: ENV.fetch("AGENT_OUTCOME", ""),
      agent_output: ENV.fetch("AGENT_OUTPUT", "")
    )
    commit_sha = ENV.fetch("REVISION_COMMIT", "")
    raise Error, "REVISION_COMMIT is required for a published revision" if status == :addressed && !commit_sha.match?(/\A[0-9a-f]{40}\z/)

    text = status_text(status, commit_sha: commit_sha)
    run_url = required_env("RUN_URL")
    summary_marker = marker(review_id)
    summary_body = <<~MARKDOWN.strip
      ## Jira Agent review update

      #{text}

      [View workflow run](#{run_url})
      #{summary_marker}
    MARKDOWN
    login = app_login(app_slug)
    upsert_issue_comment(
      repo: repo,
      pr_number: pr_number,
      token: token,
      login: login,
      response_marker: summary_marker,
      body: summary_body
    )

    inline_comment_ids.each do |comment_id|
      response_marker = marker(review_id, comment_id)
      body = <<~MARKDOWN.strip
        Jira Agent: #{text} See the [workflow run](#{run_url}) for details.
        #{response_marker}
      MARKDOWN
      upsert_inline_reply(
        repo: repo,
        pr_number: pr_number,
        comment_id: comment_id,
        token: token,
        login: login,
        response_marker: response_marker,
        body: body
      )
    end
  rescue KeyError, Error => e
    warn "::error::#{e.message}"
    exit 1
  end
end

ReviewResponse.run if $PROGRAM_NAME == __FILE__
