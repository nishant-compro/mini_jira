class ProjectsController < ApplicationController
  # GET /projects
  def index
    @projects = Project.all
    @users = User.order(:name)
    @current_user = @users.find { |user| user.id == session[:current_user_id] } || @users.first
    @user ||= User.new

    respond_to do |format|
      format.html
      format.json do
        render json: {
          projects: @projects.map { |project| project_payload(project) },
          users: @users.map { |user| user_payload(user) },
          current_user: user_payload(@current_user)
        }
      end
    end
  end

  # GET /projects/1
  def show
    @project = Project.find(params[:id])
    @tickets_by_status = @project.tickets.includes(:assignee).group_by(&:status)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          project: { id: @project.id, name: @project.name, description: @project.description },
          tickets: @project.tickets.includes(:assignee).map { |ticket| ticket_payload(ticket) },
          status_labels: { todo: "To do", in_progress: "In progress", done: "Done" }
        }
      end
    end
  end

  def new
    @project = Project.new

    respond_to do |format|
      format.html
      format.json { render json: { project: { name: "", description: "" } } }
    end
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      respond_to do |format|
        format.html { redirect_to @project, notice: "Project was successfully created." }
        format.json { render json: { redirect_url: project_path(@project) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def project_params
    params.require(:project).permit(:name, :description)
  end

  def project_payload(project)
    {
      id: project.id,
      name: project.name,
      ticket_count: project.tickets.size,
      open_tickets_count: project.open_tickets_count,
      url: project_path(project)
    }
  end

  def ticket_payload(ticket)
    {
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      status: ticket.status,
      assignee: user_payload(ticket.assignee),
      url: project_ticket_path(ticket.project, ticket)
    }
  end

  def user_payload(user)
    return nil unless user

    { id: user.id, name: user.name, email: user.email, initials: user.initials }
  end
end