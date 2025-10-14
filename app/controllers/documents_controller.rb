class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document, only: %i[ show edit update destroy ]
  before_action :set_project, only: %i[index new create]
  before_action :set_project_from_document, only: %i[show edit update destroy download duplicate archive]

  # GET /documents or /documents.json
  def index
    @documents = Document.all
  end

  # GET /documents/1 or /documents/1.json
  def show
  end

  # GET /documents/new
  def new
    @document = Document.new
  end

  # GET /documents/1/edit
  def edit
  end

  # POST /documents or /documents.json
  def create
    @document = Document.new(document_params.merge(project: @project))

    respond_to do |format|
      if @document.save
        format.html { redirect_to @document, notice: "Document was successfully created." }
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
        format.html { redirect_to @document, notice: "Document was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @document }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /documents/1 or /documents/1.json
  def destroy
    @document.destroy!

    respond_to do |format|
      format.html { redirect_to documents_path, notice: "Document was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def download
    send_data @document.file.download, filename: @document.file.filename.to_s, disposition: "attachment"
  end

  def duplicate
    new_document = @document.duplicate
    new_document.title = "Copy of " + @document.title
    if new_document.save
      redirect_to edit_document_path(new_document), notice: "Document was successfully duplicated."
    else
      redirect_to @document, alert: "Document could not be duplicated."
    end
  end

  def archive
    @document.update(archived: true)
    respond_to do |format|
      format.html { redirect_to documents_path, notice: "Document was successfully archived.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document
      @document = Document.find(params.expect(:id))
    end

    def set_project
      @project = Project.find(params[:project_id])
    end
    # Only allow a list of trusted parameters through.
    def document_params
      params.require(:document).permit(:title, :body)
    end

    def set_project_from_document
      @project = @document.project
    end
end
