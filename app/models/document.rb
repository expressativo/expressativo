class Document < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :description, presence: false, length: { minimum: 10, maximum: 1000 }


  has_one_attached :file

  validates :file, presence: true
  validate :accetable_file
  
  private

  def accetable_file
    return unless file.attached?

    if file.blob.byte_size > 10.megabytes
      errors.add(:file, "El archivo no puede ser mayor a 10 MB")
    end

    acceptable_types = ["application/pdf", "image/jpeg", "image/png"]
    unless acceptable_types.include?(file.blob.content_type)
      errors.add(:file, "Debe ser un archivo PDF, JPEG o PNG")
    end
  end
end
