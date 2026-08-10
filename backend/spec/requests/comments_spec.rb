require 'rails_helper'

RSpec.describe 'Comments', type: :request do
  let!(:project) { Project.create!(name: 'Website') }
  let!(:ticket) { project.tickets.create!(title: 'Fix login') }
  let!(:user) { User.create!(name: 'Ada Lovelace', email: 'ada@example.com') }

  describe 'POST /projects/:project_id/tickets/:ticket_id/comments' do
    it 'creates a comment with the current user' do
      post switch_users_path, params: { user_id: user.id }, as: :json

      expect {
        post project_ticket_comments_path(project, ticket),
          params: { comment: { body: 'I am investigating this.' } }, as: :json
      }.to change(Comment, :count).by(1)

      comment = Comment.last

      expect(comment.body).to eq('I am investigating this.')
      expect(comment.user).to eq(user)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig('comment', 'body')).to eq('I am investigating this.')
    end

    it 'renders the ticket with an error when invalid' do
      post switch_users_path, params: { user_id: user.id }, as: :json

      post project_ticket_comments_path(project, ticket),
        params: { comment: { body: '' } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to include("Body can't be blank")
    end
  end

  describe 'PATCH /projects/:project_id/tickets/:ticket_id/comments/:id' do
    it 'updates a comment' do
      comment = ticket.comments.create!(body: 'Initial comment', user: user)

      patch project_ticket_comment_path(project, ticket, comment),
        params: { comment: { body: 'Updated comment' } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(comment.reload.body).to eq('Updated comment')
    end
  end

  describe 'DELETE /projects/:project_id/tickets/:ticket_id/comments/:id' do
    it 'deletes a comment' do
      comment = ticket.comments.create!(body: 'Remove me', user: user)

      expect {
        delete project_ticket_comment_path(project, ticket, comment), as: :json
      }.to change(Comment, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end
end
