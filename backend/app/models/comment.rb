class Comment < ApplicationRecord
  validates :body, presence: true

  belongs_to :user
  belongs_to :ticket

  def author
    user
  end
end
