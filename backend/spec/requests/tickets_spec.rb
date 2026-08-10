require 'rails_helper'

RSpec.describe 'Tickets', type: :request do
  let!(:project) { Project.create!(name: 'Website') }
  let!(:user) { User.create!(name: 'Ada Lovelace', email: 'ada@example.com') }

  describe 'GET /projects/:project_id/tickets/new' do
    it 'renders a new ticket form with todo as the default status' do
      get new_project_ticket_path(project), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('ticket', 'status')).to eq('todo')
    end
  end

  describe 'GET /projects/:project_id/tickets/:id' do
    it 'renders the ticket and its comments' do
      ticket = project.tickets.create!(title: 'Fix login', author: user)
      ticket.comments.create!(body: 'I am investigating this.', user: user)

      get project_ticket_path(project, ticket), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('ticket', 'title')).to eq('Fix login')
      expect(response.parsed_body['comments'].first['body']).to eq('I am investigating this.')
    end
  end

  describe 'POST /projects/:project_id/tickets' do
    it 'creates a ticket with the current user as author' do
      post switch_users_path, params: { user_id: user.id }, as: :json

      expect {
        post project_tickets_path(project),
          params: { ticket: { title: 'Fix login', description: 'Investigate auth', status: 'todo' } }, as: :json
      }.to change(Ticket, :count).by(1)

      ticket = Ticket.last

      expect(ticket.author).to eq(user)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body['redirect_url']).to eq(project_ticket_path(project, ticket))
    end

    it 'renders the form when the ticket cannot be saved' do
      allow_any_instance_of(Ticket).to receive(:save).and_return(false)

      post switch_users_path, params: { user_id: user.id }, as: :json

      post project_tickets_path(project),
        params: { ticket: { title: 'Fix login' } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to be_an(Array)
    end
  end

  describe 'PATCH /projects/:project_id/tickets/:id' do
    it 'updates a ticket' do
      ticket = project.tickets.create!(title: 'Fix login', status: :todo)

      patch project_ticket_path(project, ticket),
        params: { ticket: { title: 'Fix authentication', status: 'in_progress', assignee_id: user.id } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload.title).to eq('Fix authentication')
      expect(ticket.status).to eq('in_progress')
      expect(ticket.assignee).to eq(user)
    end
  end

  describe 'DELETE /projects/:project_id/tickets/:id' do
    it 'deletes a ticket and redirects to the project' do
      ticket = project.tickets.create!(title: 'Fix login')

      expect {
        delete project_ticket_path(project, ticket), as: :json
      }.to change(Ticket, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end
end
