class ProjectSerializer < ApplicationSerializer
  attributes :id, :name, :description, :ticket_count, :open_tickets_count, :url

  def ticket_count
    object.tickets.size
  end

  def open_tickets_count
    object.open_tickets_count
  end

  def url
    project_path(object)
  end
end
