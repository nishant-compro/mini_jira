#!/usr/bin/env ruby
# frozen_string_literal: true

ALLOWED_AGENTS = %w[claude-code codex].freeze
ALLOWED_PROVIDERS = %w[bedrock openrouter].freeze
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
end

if (output = ENV["GITHUB_OUTPUT"]) && !output.empty?
  File.open(output, "a") do |file|
    file.puts "coding_agent=#{agent}"
    file.puts "model_provider=#{provider}"
    file.puts "implementer_model=#{model}"
  end
end

puts "Validated #{agent} with #{provider}"
