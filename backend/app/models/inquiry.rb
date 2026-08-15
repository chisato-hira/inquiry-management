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
  validate :staff_required_when_completed

  scope :ordered_by_priority, -> {
    order(Arel.sql("FIELD(COALESCE(priority, '未設定'), '高', '中', '低', '未設定') ASC, created_at ASC, id ASC"))
  }
  scope :ordered_by_received_at, -> { order(created_at: :asc, id: :asc) }
  scope :search, ->(query) {
    keyword = query.to_s.strip
    next none if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword)}%"
    where("name LIKE :p OR email LIKE :p OR content LIKE :p", p: pattern)
  }

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

  # 「完了」を担当者未定のまま付けると責任の所在があいまいになるため、
  # 完了に変更する時点で担当者が設定されていることを必須にする
  # (対応中までは担当者不問で自由に変更できる、実際の現場ツールに倣った運用)
  def staff_required_when_completed
    return unless status == "完了" && staff_id.blank?

    errors.add(:base, "担当者が未設定です。担当者を設定すると「完了」に移動できます")
  end
end
