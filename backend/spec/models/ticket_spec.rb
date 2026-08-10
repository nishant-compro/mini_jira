require 'rails_helper'

RSpec.describe Ticket, type: :model do
  describe 'status' do
    it 'defaults to todo' do
      ticket = Ticket.new

      expect(ticket.status).to eq('todo')
    end

    it 'supports the expected statuses' do
      expect(Ticket.statuses).to eq('todo' => 0, 'in_progress' => 1, 'done' => 2)
    end
  end

  describe 'associations' do
    it 'belongs to a project' do
      project = Project.create!(name: 'Website')
      ticket = project.tickets.create!(title: 'Ticket')

      expect(ticket.project).to eq(project)
    end

    it 'allows an optional assignee and author' do
      project = Project.create!(name: 'Website')
      ticket = project.tickets.create!(title: 'Ticket')

      expect(ticket).to be_valid
      expect(ticket.assignee).to be_nil
      expect(ticket.author).to be_nil
    end

    it 'aliases author as reporter' do
      user = User.create!(name: 'Ada Lovelace', email: 'ada@example.com')
      ticket = Ticket.create!(project: Project.create!(name: 'Website'), author: user, title: 'Ticket')

      expect(ticket.reporter).to eq(user)
    end

    it 'destroys its comments when destroyed' do
      project = Project.create!(name: 'Website')
      user = User.create!(name: 'Ada Lovelace', email: 'ada@example.com')
      ticket = project.tickets.create!(title: 'Ticket')
      comment = ticket.comments.create!(body: 'Looks good', user: user)

      expect { ticket.destroy }.to change(Comment, :count).by(-1)
      expect(Comment.exists?(comment.id)).to be(false)
    end
  end
end
