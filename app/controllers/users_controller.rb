class UsersController < ApplicationController
  def create
    @user = User.new(user_params)

    if @user.save
      respond_to do |format|
        format.html { redirect_to projects_path, notice: "User was successfully created." }
        format.json { render json: { redirect_url: projects_path }, status: :created }
      end
    else
      @projects = Project.all
      @users = User.order(:name)
      @current_user = @users.find { |user| user.id == session[:current_user_id] } || @users.first
      respond_to do |format|
        format.html { render "projects/index", status: :unprocessable_entity }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def switch
    user = User.find(params[:user_id])
    session[:current_user_id] = user.id
    respond_to do |format|
      format.html { redirect_to projects_path, notice: "Switched to #{user.name}." }
      format.json { render json: { redirect_url: projects_path } }
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end