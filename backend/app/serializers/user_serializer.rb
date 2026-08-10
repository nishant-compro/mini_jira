class UserSerializer < ApplicationSerializer
  attributes :id, :name, :initials

  def initials
    object.initials
  end
end
