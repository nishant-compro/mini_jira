require 'rails_helper'

RSpec.describe 'Projects', type: :request do
  describe 'GET /projects' do
    it 'renders the project list' do
      project = Project.create!(name: 'Website')

      get projects_path, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(project.name)
    end
  end

  describe 'GET /projects/:id' do
    it 'renders the project board' do
      project = Project.create!(name: 'Website')
      project.tickets.create!(title: 'Fix login', status: :todo)

      get project_path(project), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(project.name, 'Fix login', 'To do')
    end
  end

  describe 'POST /projects' do
    it 'creates a project and redirects to it' do
      expect {
        post projects_path, params: {
          project: { name: 'Website', description: 'Main project' }
        }, as: :json
      }.to change(Project, :count).by(1)

      project = Project.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['redirect_url']).to eq(project_path(project))
    end

    it 'renders the form with an error when invalid' do
      post projects_path, params: {
        project: { name: '', description: 'Missing name' }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to include('Name can\'t be blank')
    end
  end
end
