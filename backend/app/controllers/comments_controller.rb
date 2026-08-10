class CommentsController < ApplicationController
  def create
    @project = Project.find(params[:project_id])
    @ticket = @project.tickets.find(params[:ticket_id])
    @comment = @ticket.comments.new(comment_params.merge(user: current_user))

    if @comment.save
      respond_to do |format|
        format.html { redirect_to project_ticket_path(@project, @ticket), notice: "Comment was added." }
        format.json { render json: { comment: serialize_record(@comment, CommentSerializer) }, status: :created }
      end
    else
      @ticket = @project.tickets.includes(comments: :user).find(params[:ticket_id])
      @comments = @ticket.comments.to_a
      @users = User.order(:name)
      respond_to do |format|
        format.html { render "tickets/show", status: :unprocessable_entity }
        format.json { render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @project = Project.find(params[:project_id])
    @ticket = @project.tickets.find(params[:ticket_id])
    @comment = @ticket.comments.find(params[:id])

    if @comment.update(comment_params)
      respond_to do |format|
        format.html { redirect_to project_ticket_path(@project, @ticket), notice: "Comment was updated." }
        format.json { render json: { comment: serialize_record(@comment, CommentSerializer) } }
      end
    else
      @ticket = @project.tickets.includes(comments: :user).find(params[:ticket_id])
      @comments = @ticket.comments.to_a
      @comment = Comment.new(ticket: @ticket, user: current_user)
      respond_to do |format|
        format.html { render "tickets/show", status: :unprocessable_entity }
        format.json { render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project = Project.find(params[:project_id])
    @ticket = @project.tickets.find(params[:ticket_id])
    @ticket.comments.find(params[:id]).destroy
    respond_to do |format|
      format.html { redirect_to project_ticket_path(@project, @ticket), notice: "Comment was deleted." }
      format.json { render json: { deleted: true } }
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end

  def serialize_record(record, serializer)
    record && serializer.new(record).serializable_hash
  end
end
