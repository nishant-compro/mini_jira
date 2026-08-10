require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'validations' do
    it 'requires a name' do
      project = Project.new(name: nil)

      expect(project).not_to be_valid
      expect(project.errors[:name]).to include("can't be blank")
    end
  end

  describe '#open_tickets_count' do
    it 'counts tickets that are not done' do
      project = Project.create!(name: 'Website')
      project.tickets.create!(title: 'Todo ticket', status: :todo)
      project.tickets.create!(title: 'In progress ticket', status: :in_progress)
      project.tickets.create!(title: 'Completed ticket', status: :done)

      expect(project.open_tickets_count).to eq(2)
    end
  end

  describe 'associations' do
    it 'destroys its tickets when destroyed' do
      project = Project.create!(name: 'Website')
      ticket = project.tickets.create!(title: 'Ticket')

      expect { project.destroy }.to change(Ticket, :count).by(-1)
      expect(Ticket.exists?(ticket.id)).to be(false)
    end
  end
end
