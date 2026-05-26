class Channel < ApplicationRecord
  KINDS = %w[public private].freeze

  belongs_to :project
  belongs_to :creator, class_name: "User", foreign_key: "created_by_id"
  has_many :channel_memberships, dependent: :destroy
  has_many :members, through: :channel_memberships, source: :user
  has_many :messages, as: :messageable, dependent: :destroy

  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :project_id, case_sensitive: false }
  validates :slug, presence: true, uniqueness: { scope: :project_id }, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :kind, inclusion: { in: KINDS }

  before_validation :generate_slug, on: :create

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  private

  def generate_slug
    return if slug.present?
    return if name.blank?

    base = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
    candidate = base
    suffix = 2
    while project_id && Channel.where(project_id: project_id, slug: candidate).exists?
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    self.slug = candidate
  end
end
