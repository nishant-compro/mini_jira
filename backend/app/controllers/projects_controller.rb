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
          projects: serialize_collection(@projects, ProjectSerializer),
          users: serialize_collection(@users, UserSerializer),
          current_user: serialize_record(@current_user, UserSerializer)
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
          project: serialize_record(@project, ProjectSerializer),
          tickets: serialize_collection(@project.tickets.includes(:assignee), TicketSerializer),
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

  def serialize_record(record, serializer)
    record && serializer.new(record).serializable_hash
  end

  def serialize_collection(records, serializer)
    records.map { |record| serialize_record(record, serializer) }
  end
end
