require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'requires a name and email' do
      user = User.new

      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
      expect(user.errors[:email]).to include("can't be blank")
    end
  end

  describe '#initials' do
    it 'returns up to two uppercase initials' do
      expect(User.new(name: 'Ada Lovelace').initials).to eq('AL')
      expect(User.new(name: 'Grace').initials).to eq('G')
      expect(User.new(name: 'Ada Byron Lovelace').initials).to eq('AB')
    end

    it 'returns an empty string when the name is missing' do
      expect(User.new(name: nil).initials).to eq('')
    end
  end
end
