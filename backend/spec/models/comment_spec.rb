require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'validations' do
    it 'requires a body' do
      comment = Comment.new(body: nil)

      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'belongs to a user and ticket' do
      user = User.create!(name: 'Ada Lovelace', email: 'ada@example.com')
      ticket = Ticket.create!(project: Project.create!(name: 'Website'), title: 'Ticket')
      comment = Comment.create!(body: 'Looks good', user: user, ticket: ticket)

      expect(comment.user).to eq(user)
      expect(comment.ticket).to eq(ticket)
      expect(comment.author).to eq(user)
    end
  end
end
