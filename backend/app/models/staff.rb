class Staff < ApplicationRecord
  has_secure_password

  has_many :inquiries
  has_many :comments

  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true,
                     length: { maximum: 255 },
                     format: { with: URI::MailTo::EMAIL_REGEXP },
                     uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true
end
