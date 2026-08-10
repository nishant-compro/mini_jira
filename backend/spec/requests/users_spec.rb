require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'POST /users' do
    it 'creates a user and redirects to projects' do
      expect {
        post users_path, params: {
          user: { name: 'Ada Lovelace', email: 'ada@example.com' }
        }, as: :json
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['redirect_url']).to eq(projects_path)
    end

    it 'renders projects with an error when invalid' do
      post users_path, params: {
        user: { name: '', email: '' }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Name can', 'Email can')
    end
  end

  describe 'POST /users/switch' do
    it 'stores the selected user in the session' do
      user = User.create!(name: 'Ada Lovelace', email: 'ada@example.com')

      post switch_users_path, params: { user_id: user.id }, as: :json

      expect(response).to have_http_status(:ok)
      expect(session[:current_user_id]).to eq(user.id)
    end
  end
end
