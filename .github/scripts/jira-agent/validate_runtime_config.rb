#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

ALLOWED_AGENTS = %w[claude-code codex].freeze
ALLOWED_PROVIDERS = %w[bedrock chatgpt openrouter].freeze
SAFE_MODEL = /\A[A-Za-z0-9~][A-Za-z0-9._:\/@~-]{0,511}\z/

def fail_config(message)
  warn "::error::#{message}"
  exit 1
end

def required(name)
  value = ENV.fetch(name, "")
  fail_config("Required Jira agent configuration #{name} is missing") if value.empty?
  value
end

agent = required("CODING_AGENT")
provider = required("MODEL_PROVIDER")
model = required("MODEL_ID")

fail_config("Unsupported coding agent #{agent.inspect}") unless ALLOWED_AGENTS.include?(agent)
fail_config("Unsupported model provider #{provider.inspect}") unless ALLOWED_PROVIDERS.include?(provider)
fail_config("MODEL_ID contains unsupported characters") unless SAFE_MODEL.match?(model)

case provider
when "bedrock"
  required("AWS_ROLE_ARN")
  required("AWS_REGION")
when "openrouter"
  required("OPENROUTER_API_KEY")
when "chatgpt"
  fail_config("ChatGPT authentication is only supported with Codex") unless agent == "codex"

  begin
    auth = JSON.parse(required("CODEX_AUTH_JSON"))
  rescue JSON::ParserError
    fail_config("CODEX_AUTH_JSON is not valid JSON")
  end

  refresh_token = auth.is_a?(Hash) && auth.dig("tokens", "refresh_token")
  unless auth.is_a?(Hash) && auth["auth_mode"] == "chatgpt" && refresh_token.is_a?(String) && !refresh_token.empty?
    fail_config("CODEX_AUTH_JSON must contain ChatGPT auth with a refresh token")
  end
end

if (output = ENV["GITHUB_OUTPUT"]) && !output.empty?
  File.open(output, "a") do |file|
    file.puts "coding_agent=#{agent}"
    file.puts "model_provider=#{provider}"
    file.puts "implementer_model=#{model}"
  end
end

puts "Validated #{agent} with #{provider}"
