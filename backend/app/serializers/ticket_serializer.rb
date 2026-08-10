class TicketSerializer < ApplicationSerializer
  attributes :id, :title, :description, :status, :assignee, :reporter, :url

  def assignee
    serialize_user(object.assignee)
  end

  def reporter
    serialize_user(object.reporter)
  end

  def url
    project_ticket_path(object.project, object)
  end

  private

  def serialize_user(user)
    user && UserSerializer.new(user).serializable_hash
  end
end
