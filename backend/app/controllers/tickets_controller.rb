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
          project: serialize_record(@project, ProjectSerializer),
          ticket: serialize_record(@ticket, TicketSerializer),
          comments: serialize_collection(@comments, CommentSerializer),
          users: serialize_collection(@users, UserSerializer),
          current_user: serialize_record(current_user, UserSerializer)
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
      project: serialize_record(@project, ProjectSerializer),
      ticket: serialize_record(@ticket, TicketFormSerializer),
      users: serialize_collection(User.order(:name), UserSerializer),
      statuses: [ { value: "todo", label: "To do" }, { value: "in_progress", label: "In progress" }, { value: "done", label: "Done" } ]
    }
  end

  def serialize_record(record, serializer)
    record && serializer.new(record).serializable_hash
  end

  def serialize_collection(records, serializer)
    records.map { |record| serialize_record(record, serializer) }
  end
end
