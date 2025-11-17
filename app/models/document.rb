class Document < ApplicationRecord
  include TrackableActivity

  # Associations
  belongs_to :project
  belongs_to :folder, optional: true
  belongs_to :created_by, class_name: "User"
  has_one_attached :file
  has_rich_text :body

  # Enums
  enum :status, {
    draft: "draft",
    published: "published",
    archived: "archived"
  }

  enum :document_type, {
    document: "document",  # Rich text document
    file: "file"          # Uploaded file
  }

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :document_type, presence: true
  validate :unique_name_in_folder
  validate :file_required_for_file_type

  # Scopes
  scope :in_folder, ->(folder) { where(folder_id: folder&.id) }
  scope :root_documents, -> { where(folder_id: nil) }
  scope :not_archived, -> { where.not(status: :archived) }
  scope :for_project, ->(project) { where(project_id: project.id) }

  # Instance methods
  def path
    return [self] if folder.nil?

    folder.path + [self]
  end

  def breadcrumbs
    path.map { |item| item.is_a?(Folder) ? item.name : name }
  end

  def file_attached?
    file.attached?
  end

  private

  def unique_name_in_folder
    scope = Document.where(project_id: project_id, folder_id: folder_id)
    scope = scope.where.not(id: id) if persisted?

    if scope.exists?(name: name)
      errors.add(:name, "already exists in this location")
    end
  end

  def file_required_for_file_type
    if file? && !file.attached?
      errors.add(:file, "must be attached for file type documents")
    end
  end
end
