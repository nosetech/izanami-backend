class User < ApplicationRecord
  belongs_to :family, optional: true  # 最初は家族未設定のユーザーも許容
  has_secure_password

  enum :role, {
    admin: 'admin',
    member: 'member',
    guest: 'guest'
  }, default: 'member'

  validates :name, presence: true, length: { maximum: 200 }
  validates :email, presence: true,
                    uniqueness: true,
                    length: { maximum: 320 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
