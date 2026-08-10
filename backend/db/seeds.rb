# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

users = [
  { name: "Alice Chen", email: "alice@example.com" },
  { name: "Ben Ortiz", email: "ben@example.com" },
  { name: "Cara Silva", email: "cara@example.com" },
  { name: "Deshi Park", email: "deshi@example.com" }
].map { |attrs| User.find_or_create_by!(email: attrs[:email]) { |u| u.name = attrs[:name] } }

alice, ben, cara, deshi = users

projects = [
  { name: "Website Redesign", description: "Refresh of the marketing site", owner: alice },
  { name: "Mobile App", description: "iOS and Android client", owner: ben },
  { name: "Internal Tools", description: "Admin dashboards and scripts", owner: cara }
].map { |attrs| Project.find_or_create_by!(name: attrs[:name]) { |p| p.assign_attributes(attrs.except(:name)) } }

website, mobile, internal = projects

ticket_data = [
  { project: website, title: "Update hero section copy", ticket_type: :task, status: :todo, assignee: ben, reporter: alice },
  { project: website, title: "Fix mobile nav overlap", ticket_type: :bug, status: :todo, assignee: cara, reporter: alice },
  { project: website, title: "Add pricing page", ticket_type: :task, status: :in_progress, assignee: alice, reporter: ben },
  { project: website, title: "Broken footer links", ticket_type: :bug, status: :in_progress, assignee: deshi, reporter: cara },
  { project: website, title: "Set up analytics", ticket_type: :task, status: :done, assignee: ben, reporter: alice },
  { project: website, title: "Optimize image loading", ticket_type: :task, status: :done, assignee: cara, reporter: ben },

  { project: mobile, title: "Push notification crash", ticket_type: :bug, status: :todo, assignee: deshi, reporter: ben },
  { project: mobile, title: "Dark mode support", ticket_type: :task, status: :in_progress, assignee: ben, reporter: cara },
  { project: mobile, title: "Onboarding flow polish", ticket_type: :task, status: :done, assignee: alice, reporter: deshi },

  { project: internal, title: "Admin login timeout", ticket_type: :bug, status: :todo, assignee: cara, reporter: deshi },
  { project: internal, title: "Export CSV reports", ticket_type: :task, status: :in_progress, assignee: deshi, reporter: alice }
].map do |attrs|
  Ticket.find_or_create_by!(project: attrs[:project], title: attrs[:title]) do |t|
    t.ticket_type = attrs[:ticket_type]
    t.status = attrs[:status]
    t.assignee = attrs[:assignee]
    t.reporter = attrs[:reporter]
    t.description = "Details for #{attrs[:title].downcase}. This ticket tracks the work needed to complete the task and keep the project on schedule."
  end
end

pricing_ticket = ticket_data.find { |t| t.title == "Add pricing page" }

if pricing_ticket
  [
    { user: ben, body: "I've started on the layout, should have a first pass by tomorrow." },
    { user: alice, body: "Great, let's make sure it matches the new brand colors." },
    { user: cara, body: "Can you also add a FAQ section at the bottom?" }
  ].each do |attrs|
    Comment.find_or_create_by!(ticket: pricing_ticket, user: attrs[:user], body: attrs[:body])
  end
end

