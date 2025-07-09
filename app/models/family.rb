class Family < ApplicationRecord
  has_many :users, dependent: :destroy

  validates :name, presence: true, length: { maximum: 200 }

  scope :active, -> { where(deleted_at: nil) }
end
