class FoldersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_folder, only: [ :show, :edit, :update, :destroy ]
  before_action :set_parent_folder, only: [ :new, :create ]

  def index
    folders = @project.folders.includes(:created_by).root_folders
    documents = @project.documents.includes(:created_by).root_documents.not_archived

    # Combine and sort by created_at (most recent first)
    @items = (folders.to_a + documents.to_a).sort_by(&:created_at).reverse
  end

  def show
    subfolders = @folder.subfolders.includes(:created_by)
    documents = @folder.documents.includes(:created_by).not_archived

    # Combine and sort by created_at (most recent first)
    @items = (subfolders.to_a + documents.to_a).sort_by(&:created_at).reverse
  end

  def new
    @folder = @project.folders.build(parent_folder: @parent_folder)
  end

  def create
    @folder = @project.folders.build(folder_params)
    @folder.parent_folder = @parent_folder
    @folder.created_by = current_user

    if @folder.save
      redirect_to project_folder_path(@project, @folder), notice: "Folder was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @folder.update(folder_params)
      redirect_to project_folder_path(@project, @folder), notice: "Folder was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    parent = @folder.parent_folder

    @folder.destroy
    redirect_to parent ? project_folder_path(@project, parent) : project_folders_path(@project),
                notice: "Folder was successfully deleted."
  end

  private

  def set_folder
    @folder = Folder.find(params[:id])
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_parent_folder
    @parent_folder = params[:parent_folder_id].present? ? Folder.find(params[:parent_folder_id]) : nil
  end

  def folder_params
    params.require(:folder).permit(:name, :parent_folder_id)
  end
end
