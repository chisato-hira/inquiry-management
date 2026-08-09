class StatsController < ApplicationController
  before_action :require_login

  def show
    render json: {
      status_counts: status_counts,
      category_counts: category_counts,
      staff_incomplete_counts: staff_incomplete_counts
    }
  end

  private

  def status_counts
    counts = Inquiry.group(:status).count
    Inquiry::STATUSES.index_with { |status| counts[status] || 0 }
  end

  def category_counts
    counts = Inquiry.group(:category).count
    Inquiry::CATEGORIES.index_with { |category| counts[category] || 0 }
  end

  # staff_idがnilの問い合わせ(未割当)も「未割当」エントリとして末尾に含める。
  # こうしないと、このAPIのstaff_incomplete_countsの合計とstatus_countsの
  # 未対応+対応中の合計が食い違い、統計として矛盾したものになる。
  def staff_incomplete_counts
    counts = Inquiry.where(status: %w[未対応 対応中]).group(:staff_id).count

    assigned = Staff.order(:name).map do |staff|
      { staff_id: staff.id, name: staff.name, count: counts[staff.id] || 0 }
    end

    assigned + [ { staff_id: nil, name: "未割当", count: counts[nil] || 0 } ]
  end
end
