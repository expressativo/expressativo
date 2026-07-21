class CliAccessToken < ApplicationRecord
  belongs_to :user

  attr_reader :raw_token

  before_validation :generate_token, on: :create

  validates :token_digest, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    digest = digest_token(raw_token)
    token = find_by(token_digest: digest)
    return nil if token.nil?
    return nil if token.revoked_at.present?
    return nil if token.expires_at.present? && token.expires_at <= Time.current

    token.touch(:last_used_at)
    token
  end

  def self.digest_token(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  private

  def generate_token
    return if token_digest.present?

    @raw_token = SecureRandom.urlsafe_base64(32)
    self.token_digest = self.class.digest_token(@raw_token)
  end
end
