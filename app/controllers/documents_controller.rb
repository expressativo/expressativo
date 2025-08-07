class DocumentsController < ApplicationController
  before_action :set_doc, only: [ :show, :edit, :update, :destroy ]

  def index
    @documents = Document.all
  end

  def show
  end

  def new
    @doc = Document.new
  end

  def create
    @doc = Document.new(doc_params)

    if @doc.save
      redirect_to @doc, notice: "Documento creado exitosamente"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @doc.update(doc_params)
      redirect_to @doc, notice: "Documento actualizado exitosamente"
    else
      render :edit
    end
  end

  def destroy
    @doc.destroy
    redirect_to docs_path, notice: "Documento eliminado exitosamente"
  end

  private

  def set_doc
    @doc = Document.find(params[:id])
  end

  def doc_params
    params.require(:document).permit(:name, :description, :file)
  end
end
