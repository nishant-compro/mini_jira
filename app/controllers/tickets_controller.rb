class TicketsController < ApplicationController
  def show
    @project = Project.find(params[:project_id])
    @ticket = @project.tickets.includes(comments: :user).find(params[:id])
    @comments = @ticket.comments.to_a
    @comment = @ticket.comments.new(user: current_user)
    @users = User.order(:name)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          project: { id: @project.id, name: @project.name },
          ticket: ticket_payload(@ticket),
          comments: @comments.map { |comment| comment_payload(comment) },
          users: @users.map { |user| user_payload(user) },
          current_user: user_payload(current_user)
        }
      end
    end
  end

  def new
    @project = Project.find(params[:project_id])
    @ticket = @project.tickets.new(status: :todo)

    respond_to do |format|
      format.html
      format.json { render json: form_payload }
    end
  end

  def create
    @project = Project.find(params[:project_id])
    @ticket = @project.tickets.new(ticket_params.merge(author: current_user))

    if @ticket.save
      respond_to do |format|
        format.html { redirect_to project_ticket_path(@project, @ticket), notice: "Ticket was successfully created." }
        format.json { render json: { redirect_url: project_ticket_path(@project, @ticket) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @project = Project.find(params[:project_id])
    @ticket = @project.tickets.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: form_payload }
    end
  end

  def update
    @project = Project.find(params[:project_id])
    @ticket = @project.tickets.find(params[:id])

    if @ticket.update(ticket_params)
      respond_to do |format|
        format.html { redirect_to project_ticket_path(@project, @ticket), notice: "Ticket was successfully updated." }
        format.json { render json: { redirect_url: project_ticket_path(@project, @ticket) } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project = Project.find(params[:project_id])
    @ticket = @project.tickets.find(params[:id])
    @ticket.destroy
    respond_to do |format|
      format.html { redirect_to project_path(@project), notice: "Ticket was deleted." }
      format.json { render json: { redirect_url: project_path(@project) } }
    end
  end

  private

  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :assignee_id)
  end

  def form_payload
    {
      project: { id: @project.id, name: @project.name },
      ticket: { id: @ticket.id, title: @ticket.title, description: @ticket.description, status: @ticket.status, assignee_id: @ticket.assignee_id },
      users: User.order(:name).map { |user| user_payload(user) },
      statuses: [{ value: "todo", label: "To do" }, { value: "in_progress", label: "In progress" }, { value: "done", label: "Done" }]
    }
  end

  def ticket_payload(ticket)
    {
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      status: ticket.status,
      assignee: user_payload(ticket.assignee),
      reporter: user_payload(ticket.reporter),
      edit_url: edit_project_ticket_path(@project, ticket),
      url: project_ticket_path(@project, ticket)
    }
  end

  def comment_payload(comment)
    { id: comment.id, body: comment.body, author: user_payload(comment.user) }
  end

  def user_payload(user)
    return nil unless user

    { id: user.id, name: user.name, email: user.email, initials: user.initials }
  end
end