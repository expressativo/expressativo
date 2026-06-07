class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document, only: %i[ show edit update destroy download duplicate archive unarchive publish unpublish publish_public unpublish_public ]
  before_action :set_project, only: %i[index new create archived]
  before_action :set_folder, only: %i[new create]
  before_action :set_project_from_document, only: %i[show edit update destroy download duplicate archive unarchive publish unpublish publish_public unpublish_public]
  before_action :authorize_status_change!, only: %i[archive unarchive publish unpublish publish_public unpublish_public]

  # GET /documents or /documents.json
  def index
    # This redirects to folders index which shows the root level
    redirect_to project_folders_path(@project)
  end

  # GET /documents/1 or /documents/1.json
  def show
  end

  # GET /documents/new
  def new
    @document = @project.documents.build(folder: @folder)
    # Set document_type based on URL parameter, default to 'document'
    @document.document_type = params[:type] == "file" ? :file : :document
  end

  # GET /documents/1/edit
  def edit
  end

  # POST /documents or /documents.json
  def create
    @document = @project.documents.build(document_params)
    @document.folder = @folder
    @document.created_by = current_user

    respond_to do |format|
      if @document.save
        redirect_path = @folder ? project_folder_path(@project, @folder) : project_folders_path(@project)
        format.html { redirect_to redirect_path, notice: "Documento creado." }
        format.json { render :show, status: :created, location: @document }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /documents/1 or /documents/1.json
  def update
    respond_to do |format|
      if @document.update(document_params)
        format.html { redirect_to @document, notice: "Documento actualizado exitosamente", status: :see_other }
        format.json { render :show, status: :ok, location: @document }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /documents/1 or /documents/1.json
  def destroy
    folder = @document.folder
    @document.destroy!

    respond_to do |format|
      redirect_path = folder ? project_folder_path(@project, folder) : project_folders_path(@project)
      format.html { redirect_to redirect_path, notice: "Documento eliminado exitosamente", status: :see_other }
      format.json { head :no_content }
    end
  end

  def download
    if @document.file.attached?
      send_data @document.file.download, filename: @document.file.filename.to_s, disposition: "attachment"
    else
      redirect_to @document, alert: "No file attached to this document."
    end
  end

  def duplicate
    new_document = @document.dup
    new_document.name = "Copy of #{@document.name}"
    new_document.created_by = current_user
    new_document.status = :draft

    # Copy file if attached
    if @document.file.attached?
      new_document.file.attach(@document.file.blob)
    end

    if new_document.save
      redirect_to edit_document_path(new_document), notice: "Document was successfully duplicated."
    else
      redirect_to @document, alert: "Document could not be duplicated."
    end
  end

  def archive
    @document.update(status: :archived)
    respond_to do |format|
      redirect_path = @document.folder ? project_folder_path(@project, @document.folder) : project_folders_path(@project)
      format.html { redirect_to redirect_path, notice: "Documento archivado.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def unarchive
    @document.update(status: :draft)
    respond_to do |format|
      format.html { redirect_to project_archived_documents_path(@project), notice: "Documento restaurado como borrador.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def publish
    @document.update(status: :published)
    respond_to do |format|
      format.html { redirect_to @document, notice: "Documento publicado.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def unpublish
    @document.update(status: :draft)
    respond_to do |format|
      format.html { redirect_to @document, notice: "Documento movido a borrador.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def publish_public
    @document.publish_publicly!
    redirect_to @document, notice: "Documento publicado públicamente. Cualquiera con el link puede verlo.", status: :see_other
  end

  def unpublish_public
    @document.unpublish_publicly!
    redirect_to @document, notice: "Documento marcado como privado. El link público fue revocado.", status: :see_other
  end

  def archived
    @documents = @project.documents
                         .includes(:created_by, :folder)
                         .archived_only
                         .order(updated_at: :desc)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document
      @document = Document.joins(project: :project_users)
                          .where(project_users: { user_id: current_user.id })
                          .visible_to(current_user)
                          .find(params.expect(:id))
    end

    def set_project
      @project = Project.for_user(current_user).find(params[:project_id])
    end

    def set_folder
      @folder = params[:folder_id].present? ? @project.folders.find(params[:folder_id]) : nil
    end

    # Only allow a list of trusted parameters through.
    def document_params
      params.require(:document).permit(:name, :body, :file, :document_type)
    end

    def set_project_from_document
      @project = @document.project
    end

    def authorize_status_change!
      return if @document.can_be_published_by?(current_user)

      redirect_to @document, alert: "No tienes permisos para cambiar el estado de este documento.", status: :see_other
    end
end
