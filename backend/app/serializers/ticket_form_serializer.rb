class TicketFormSerializer < ApplicationSerializer
  attributes :id, :title, :description, :status, :assignee_id
end
