class Inquiry < ApplicationRecord
  CATEGORIES = %w[料金プラン 使い方 解約 不具合 その他].freeze
  STATUSES   = %w[未対応 対応中 完了].freeze
  PRIORITIES = %w[未設定 高 中 低].freeze

  PRIORITY_KEYWORDS = %w[
    至急 緊急 今すぐ 早急に
    クレーム 苦情 不満
    ログインできない 使えない 解約したい 決済エラー
  ].freeze

  belongs_to :staff, optional: true
  has_many :comments, dependent: :destroy

  before_validation :auto_set_priority_from_keywords, on: :create

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

  def priority_auto_set_by_keyword?
    @priority_auto_set_by_keyword.present?
  end

  private

  def auto_set_priority_from_keywords
    return if content.blank?
    return unless PRIORITY_KEYWORDS.any? { |keyword| content.include?(keyword) }

    self.priority = "高"
    @priority_auto_set_by_keyword = true
  end
end
