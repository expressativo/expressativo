class DocumentPdfExportJob < ApplicationJob
  queue_as :default

  # Renderiza el documento rich_text a PDF en background y notifica al usuario
  # por ActionCable cuando está listo (o si falla).
  #
  # @param document_id [Integer]
  # @param user_id [Integer]  usuario que pidió la exportación (destinatario del broadcast)
  def perform(document_id, user_id)
    document = Document.find_by(id: document_id)
    user = User.find_by(id: user_id)
    return if document.nil? || user.nil?

    pdf_data = DocumentPdfExporter.call(document)

    filename = "#{document.name.parameterize}.pdf"
    document.pdf_export.purge if document.pdf_export.attached?
    document.pdf_export.attach(
      io: StringIO.new(pdf_data),
      filename: filename,
      content_type: "application/pdf"
    )

    url = Rails.application.routes.url_helpers.rails_blob_path(document.pdf_export, disposition: "attachment")

    NotificationsChannel.broadcast_to(user, {
      action: "pdf_ready",
      document_id: document.id,
      url: url,
      filename: filename
    })
  rescue => e
    Rails.logger.error("[DocumentPdfExportJob] #{e.class}: #{e.message}")
    NotificationsChannel.broadcast_to(user, {
      action: "pdf_error",
      document_id: document_id,
      message: "No se pudo generar el PDF."
    }) if user
  end
end
