class Housework < ApplicationRecord
  belongs_to :family
  belongs_to :suggested_by, class_name: "User"

  enum :category, {
    cooking: 0,
    cleaning: 1,
    shopping: 2,
    laundry: 3,
    other: 4
  }

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 500 }
  validates :schedule, length: { maximum: 100 }
  validates :point, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :committed, inclusion: { in: [ true, false ] }

  scope :active, -> { where(deleted_at: nil) }
  scope :committed, -> { where(committed: true) }
  scope :uncommitted, -> { where(committed: false) }
end
