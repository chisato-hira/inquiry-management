class Inquiry < ApplicationRecord
  CATEGORIES = %w[料金プラン 使い方 解約 不具合 その他].freeze
  STATUSES   = %w[未対応 対応中 完了].freeze
  PRIORITIES = %w[未設定 高 中 低].freeze

  belongs_to :staff, optional: true
  has_many :comments, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, length: { maximum: 20 }, allow_blank: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }, allow_nil: true

  scope :ordered_by_priority, -> {
    order(Arel.sql("FIELD(COALESCE(priority, '未設定'), '高', '中', '低', '未設定') ASC, created_at ASC, id ASC"))
  }
  scope :ordered_by_received_at, -> { order(created_at: :asc, id: :asc) }
end
