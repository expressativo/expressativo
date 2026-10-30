# Mover documentos y carpetas entre carpetas del mismo proyecto.
# Responde con turbo_stream (quita la tarjeta de la vista actual y muestra un
# toast) o, sin JS, redirige de vuelta.
module DriveMoves
  extend ActiveSupport::Concern

  private

  # attribute: :folder para documentos, :parent_folder para carpetas.
  # params[:folder_id] vacío = raíz del proyecto.
  def move_drive_item(item, attribute)
    destination = params[:folder_id].present? ? @project.folders.find(params[:folder_id]) : nil
    destination_name = destination&.name || "Documentos"

    if item.public_send(attribute) == destination
      respond_to_drive_move(item, moved: false, type: "notice", message: "“#{item.name}” ya está en #{destination_name}.")
    elsif item.update(attribute => destination)
      respond_to_drive_move(item, moved: true, type: "success", message: "“#{item.name}” se movió a #{destination_name}.")
    else
      respond_to_drive_move(item, moved: false, type: "alert", message: drive_move_error(item, destination_name),
                            status: :unprocessable_entity)
    end
  end

  def respond_to_drive_move(item, moved:, type:, message:, status: :ok)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          (turbo_stream.remove(item) if moved),
          turbo_stream.append("toasts", partial: "shared/toast", locals: { message: message, type: type })
        ].compact, status: status
      end
      format.html do
        flash_key = type == "alert" ? :alert : :notice
        redirect_back_or_to project_folders_path(@project), flash_key => message, status: :see_other
      end
    end
  end

  def drive_move_error(item, destination_name)
    if item.errors.include?(:parent_folder_id)
      "No se puede mover una carpeta dentro de sí misma."
    elsif item.errors.include?(:name)
      "Ya existe un elemento llamado “#{item.name}” en #{destination_name}."
    else
      item.errors.full_messages.to_sentence
    end
  end
end
