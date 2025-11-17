class Folder < ApplicationRecord
  include TrackableActivity

  # Associations
  belongs_to :project
  belongs_to :parent_folder, class_name: "Folder", optional: true
  belongs_to :created_by, class_name: "User"

  has_many :subfolders, class_name: "Folder", foreign_key: :parent_folder_id, dependent: :destroy
  has_many :documents, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :project_id, presence: true
  validate :prevent_circular_reference
  validate :unique_name_in_scope

  # Scopes
  scope :root_folders, -> { where(parent_folder_id: nil) }
  scope :for_project, ->(project) { where(project_id: project.id) }

  # Instance methods
  def path
    return [self] if parent_folder.nil?

    parent_folder.path + [self]
  end

  def breadcrumbs
    path.map(&:name)
  end

  def all_parent_ids
    return [] if parent_folder.nil?

    [parent_folder.id] + parent_folder.all_parent_ids
  end

  private

  def prevent_circular_reference
    return if parent_folder_id.nil?

    if id == parent_folder_id
      errors.add(:parent_folder_id, "cannot reference itself")
      return
    end

    if id.present? && all_parent_ids.include?(id)
      errors.add(:parent_folder_id, "cannot create circular reference")
    end
  end

  def unique_name_in_scope
    scope = Folder.where(project_id: project_id, parent_folder_id: parent_folder_id)
    scope = scope.where.not(id: id) if persisted?

    if scope.exists?(name: name)
      errors.add(:name, "already exists in this location")
    end
  end
end
