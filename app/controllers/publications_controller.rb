class PublicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_publication, only: [:update, :destroy, :update_date]

  def index
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month
    
    # Asegurar que el mes esté en rango válido
    @month = 1 if @month < 1
    @month = 12 if @month > 12
    
    @date = Date.new(@year, @month, 1)
    @publications = @project.publications.for_month(@year, @month).order(:publication_date)
    
    # Agrupar publicaciones por fecha para el calendario
    @publications_by_date = @publications.group_by(&:publication_date)
  end

  def create
    @publication = @project.publications.build(publication_params)
    @publication.created_by = current_user
    
    if @publication.save
      render json: { 
        success: true, 
        publication: publication_json(@publication),
        message: "Publicación creada exitosamente"
      }
    else
      render json: { 
        success: false, 
        errors: @publication.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  def update
    if @publication.update(publication_params)
      render json: { 
        success: true, 
        publication: publication_json(@publication),
        message: "Publicación actualizada exitosamente"
      }
    else
      render json: { 
        success: false, 
        errors: @publication.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @publication.destroy
    render json: { 
      success: true, 
      message: "Publicación eliminada exitosamente" 
    }
  end

  def update_date
    new_date = Date.parse(params[:new_date])
    
    if @publication.update(publication_date: new_date)
      render json: { 
        success: true, 
        message: "Fecha actualizada exitosamente" 
      }
    else
      render json: { 
        success: false, 
        errors: @publication.errors.full_messages 
      }, status: :unprocessable_entity
    end
  rescue ArgumentError
    render json: { 
      success: false, 
      errors: ["Fecha inválida"] 
    }, status: :unprocessable_entity
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end

  def set_publication
    @publication = @project.publications.find(params[:id])
  end

  def publication_params
    params.require(:publication).permit(:title, :description, :publication_date)
  end

  def publication_json(publication)
    {
      id: publication.id,
      title: publication.title,
      description: publication.description,
      publication_date: publication.publication_date.to_s,
      task_id: publication.task_id,
      has_task: publication.task.present?
    }
  end
end
