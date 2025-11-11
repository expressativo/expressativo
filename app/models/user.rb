class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :sessions, dependent: :destroy
  has_one_attached :avatar
  has_many :project_users, dependent: :destroy
  has_many :projects, through: :project_users

  # valida que sea una imagen
  validates :avatar, content_type: [ "image/png", "image/jpeg" ], size: { less_than: 5.megabytes }

  def full_name
    "#{first_name} #{last_name}"
  end
end
