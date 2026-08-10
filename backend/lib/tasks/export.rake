require "fileutils"
require "json"

module MiniJiraExport
  module_function

  def format
    ENV.fetch("FORMAT", "csv").downcase
  end

  def output_dir
    Rails.root.join(ENV.fetch("OUTPUT_DIR", "tmp/exports"))
  end

  def export(name, headers, rows)
    raise ArgumentError, "Unsupported FORMAT=#{format.inspect}. Use csv or json." unless %w[csv json].include?(format)

    FileUtils.mkdir_p(output_dir)

    path = output_dir.join("#{name}.#{format}")
    data = rows.map(&:call)

    if format == "json"
      File.write(path, JSON.pretty_generate(data))
    else
      require "csv"

      CSV.open(path, "w", write_headers: true, headers: headers) do |csv|
        data.each { |row| csv << headers.map { |header| row[header] } }
      end
    end

    puts "Exported #{data.size} #{name} records to #{path}"
  end

  def users
    headers = %w[id name email created_at updated_at]
    rows = User.order(:id).map do |user|
      -> {
        {
          "id" => user.id,
          "name" => user.name,
          "email" => user.email,
          "created_at" => user.created_at&.iso8601,
          "updated_at" => user.updated_at&.iso8601
        }
      }
    end

    export("users", headers, rows)
  end

  def projects
    headers = %w[id name description tickets_count open_tickets_count created_at updated_at]
    rows = Project.includes(:tickets).order(:id).map do |project|
      -> {
        {
          "id" => project.id,
          "name" => project.name,
          "description" => project.description,
          "tickets_count" => project.tickets.count,
          "open_tickets_count" => project.open_tickets_count,
          "created_at" => project.created_at&.iso8601,
          "updated_at" => project.updated_at&.iso8601
        }
      }
    end

    export("projects", headers, rows)
  end

  def tickets
    headers = %w[
      id title description status project_id project_name assignee_id assignee_name assignee_email
      author_id author_name author_email comments_count created_at updated_at
    ]
    rows = Ticket.includes(:project, :assignee, :author, :comments).order(:id).map do |ticket|
      -> {
        {
          "id" => ticket.id,
          "title" => ticket.title,
          "description" => ticket.description,
          "status" => ticket.status,
          "project_id" => ticket.project_id,
          "project_name" => ticket.project&.name,
          "assignee_id" => ticket.assignee_id,
          "assignee_name" => ticket.assignee&.name,
          "assignee_email" => ticket.assignee&.email,
          "author_id" => ticket.author_id,
          "author_name" => ticket.author&.name,
          "author_email" => ticket.author&.email,
          "comments_count" => ticket.comments.size,
          "created_at" => ticket.created_at&.iso8601,
          "updated_at" => ticket.updated_at&.iso8601
        }
      }
    end

    export("tickets", headers, rows)
  end

  def comments
    headers = %w[
      id body ticket_id ticket_title project_id project_name user_id user_name user_email created_at updated_at
    ]
    rows = Comment.includes(:user, ticket: :project).order(:id).map do |comment|
      -> {
        {
          "id" => comment.id,
          "body" => comment.body,
          "ticket_id" => comment.ticket_id,
          "ticket_title" => comment.ticket&.title,
          "project_id" => comment.ticket&.project_id,
          "project_name" => comment.ticket&.project&.name,
          "user_id" => comment.user_id,
          "user_name" => comment.user&.name,
          "user_email" => comment.user&.email,
          "created_at" => comment.created_at&.iso8601,
          "updated_at" => comment.updated_at&.iso8601
        }
      }
    end

    export("comments", headers, rows)
  end
end

namespace :export do
  desc "Export users to tmp/exports/users.csv. Use FORMAT=json or OUTPUT_DIR=path to customize."
  task users: :environment do
    MiniJiraExport.users
  end

  desc "Export projects to tmp/exports/projects.csv. Use FORMAT=json or OUTPUT_DIR=path to customize."
  task projects: :environment do
    MiniJiraExport.projects
  end

  desc "Export tickets to tmp/exports/tickets.csv. Use FORMAT=json or OUTPUT_DIR=path to customize."
  task tickets: :environment do
    MiniJiraExport.tickets
  end

  desc "Export comments to tmp/exports/comments.csv. Use FORMAT=json or OUTPUT_DIR=path to customize."
  task comments: :environment do
    MiniJiraExport.comments
  end

  desc "Export users, projects, tickets, and comments. Use FORMAT=json or OUTPUT_DIR=path to customize."
  task all: :environment do
    MiniJiraExport.users
    MiniJiraExport.projects
    MiniJiraExport.tickets
    MiniJiraExport.comments
  end
end
