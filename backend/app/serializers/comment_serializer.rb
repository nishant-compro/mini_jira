class CommentSerializer < ApplicationSerializer
  attributes :id, :body, :author

  def author
    UserSerializer.new(object.user).serializable_hash
  end
end
