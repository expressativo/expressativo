class FolderUploadsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action -> { require_non_viewer!(@project) }

  # POST /projects/:project_id/folder_uploads
  # Params: parent_folder_id (opcional), entries: [{ path:, signed_id: } | { path:, directory: true }]
  def create
    parent_folder = params[:parent_folder_id].present? ? @project.folders.find(params[:parent_folder_id]) : nil
    entries = params.fetch(:entries, []).map { |e| e.permit(:path, :signed_id, :directory).to_h }

    uploader = FolderUploader.new(project: @project, user: current_user, parent_folder: parent_folder, entries: entries).call

    target = uploader.root_folders.one? ? uploader.root_folders.first : parent_folder
    redirect_url = target ? project_folder_path(@project, target) : project_folders_path(@project)
    count = uploader.documents.size
    flash[:notice] = case count
    when 0 then "Carpeta subida."
    when 1 then "1 archivo subido."
    else "#{count} archivos subidos."
    end

    render json: { redirect_url: redirect_url }, status: :created
  rescue FolderUploader::Error, ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end
end
