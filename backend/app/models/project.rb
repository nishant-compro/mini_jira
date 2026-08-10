class Project < ApplicationRecord
    validates :name, presence: true

    has_many :tickets, dependent: :destroy

    def open_tickets_count
        tickets.where.not(status: "done").count
    end
end
