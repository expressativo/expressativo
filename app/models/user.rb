class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one_attached :avatar
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true


  # valida que sea una imagen
  validates :avatar, content_type: [ "image/png", "image/jpeg" ], size: { less_than: 5.megabytes }
end
