class User < ApplicationRecord
    validates :name, :email, presence: true

    def initials
        name.to_s.split.map { |part| part[0] }.join.upcase.first(2)
    end
end
