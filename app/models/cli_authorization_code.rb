class CliAuthorizationCode < ApplicationRecord
  belongs_to :user

  attr_reader :raw_code

  before_validation :generate_code, on: :create

  validates :code_digest, presence: true, uniqueness: true
  validates :redirect_uri, presence: true
  validate :redirect_uri_must_be_local

  scope :active, -> { where("expires_at > ?", Time.current) }

  EXPIRES_IN = 5.minutes.freeze
  ALLOWED_HOSTS = %w[127.0.0.1 localhost].freeze

  def self.consume!(raw_code, verifier: nil)
    return nil if raw_code.blank?

    digest = digest_code(raw_code)
    code = find_by(code_digest: digest)
    return nil if code.nil?
    return nil if code.expires_at <= Time.current

    if code.code_challenge.present?
      return nil if verifier.blank?
      computed = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
      return nil unless ActiveSupport::SecurityUtils.secure_compare(computed, code.code_challenge)
    end

    transaction do
      code.destroy
    end
    code
  end

  def self.digest_code(raw_code)
    Digest::SHA256.hexdigest(raw_code.to_s)
  end

  def expired?
    expires_at <= Time.current
  end

  private

  def generate_code
    return if code_digest.present?

    @raw_code = SecureRandom.urlsafe_base64(32)
    self.code_digest = self.class.digest_code(@raw_code)
    self.expires_at = Time.current + EXPIRES_IN
  end

  def redirect_uri_must_be_local
    return if redirect_uri.blank?

    uri = URI.parse(redirect_uri)
    errors.add(:redirect_uri, "debe usar http") unless uri.scheme == "http"
    errors.add(:redirect_uri, "debe apuntar a localhost o 127.0.0.1") unless ALLOWED_HOSTS.include?(uri.host)
  end
end
