#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

base = URI(ENV.fetch("JIRA_BASE_URL"))
raise "JIRA_BASE_URL must use HTTPS" unless base.is_a?(URI::HTTPS)

issue_key = ENV.fetch("ISSUE_KEY")
message = ENV.fetch("JIRA_COMMENT")[0, 8_000]
uri = URI.join("#{base.to_s.delete_suffix("/")}/", "rest/api/3/issue/#{URI.encode_www_form_component(issue_key)}/comment")
request = Net::HTTP::Post.new(uri)
request["Accept"] = "application/json"
request["Content-Type"] = "application/json"
request["Authorization"] = "Bearer #{ENV.fetch("JIRA_API_TOKEN")}"
request.body = JSON.generate(
  body: {
    type: "doc",
    version: 1,
    content: [{ type: "paragraph", content: [{ type: "text", text: message }] }]
  }
)
response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 30) { |http| http.request(request) }
raise "Jira comment failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

puts "Updated Jira issue #{issue_key}"
