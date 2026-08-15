class InquiriesController < ApplicationController
  before_action :require_login, except: %i[create]
  before_action :verify_csrf_token!, only: %i[update]

  PER_PAGE = 20
  COMPLETED_RETENTION = 30.days

  def index
    scope = Inquiry.includes(:staff)

    if params[:status].present?
      return render_error("invalid status", status: :bad_request) unless Inquiry::STATUSES.include?(params[:status])

      scope = scope.where(status: params[:status])
      # 完了は際限なく溜まっていくため、ボードを見づらくしないよう直近30日以内のみをデフォルトで表示する
      scope = scope.where(updated_at: COMPLETED_RETENTION.ago..) if params[:status] == "完了"
    end

    scope = params[:sort] == "priority" ? scope.ordered_by_priority : scope.ordered_by_received_at

    page = [ params[:page].to_i, 1 ].max
    total_count = scope.count
    inquiries = scope.limit(PER_PAGE).offset((page - 1) * PER_PAGE)

    render json: {
      inquiries: inquiries.map { |inquiry| inquiry_json(inquiry) },
      meta: {
        page: page,
        per_page: PER_PAGE,
        total_count: total_count,
        has_more: total_count > page * PER_PAGE
      }
    }
  end

  def show
    inquiry = Inquiry.includes(:staff, comments: :staff).find(params[:id])
    comments = inquiry.comments.sort_by { |comment| [ comment.created_at, comment.id ] }

    render json: inquiry_json(inquiry).merge(comments: comments.map { |comment| comment_json(comment) })
  end

  def create
    inquiry = Inquiry.new(inquiry_params)

    unless inquiry.save
      return render_error(inquiry.errors.full_messages.join(" / "))
    end

    # inquiry自体は既に保存済みのため、以降のシステムコメント作成・確認メール送信が
    # 失敗しても顧客に「登録失敗」と誤認させて再送信(=重複登録)させないよう、
    # 例外は握りつぶしてエラーレポートに記録するのみに留める(updateアクションとは非対称)。
    begin
      ActiveRecord::Base.transaction do
        inquiry.comments.create!(comment_type: "system", staff: nil, content: "問い合わせを受け付けました")

        if inquiry.priority_auto_set_by_keyword?
          inquiry.comments.create!(comment_type: "system", staff: nil, content: "キーワード検出により優先度を「高」に自動設定しました")
        end
      end
    rescue StandardError => e
      Rails.error.report(e, handled: true, context: { inquiry_id: inquiry.id })
    end

    begin
      InquiryMailer.confirmation(inquiry).deliver_later
    rescue StandardError => e
      Rails.error.report(e, handled: true, context: { inquiry_id: inquiry.id })
    end

    render json: inquiry_json(inquiry), status: :created
  end

  def update
    inquiry = Inquiry.find(params[:id])

    return render_error("lock_versionが必要です") if inquiry_update_params[:lock_version].blank?

    changed_fields = inquiry_update_params.to_h.keys & %w[status priority staff_id]
    return render_error("更新項目がありません") if changed_fields.empty?

    if inquiry_update_params.key?(:staff_id)
      staff_id = inquiry_update_params[:staff_id].presence
      return render_error("指定された担当者が見つかりません") if staff_id.present? && !Staff.exists?(id: staff_id)
    end

    old_status = inquiry.status
    old_priority = inquiry.priority
    old_staff = inquiry.staff

    begin
      ActiveRecord::Base.transaction do
        attrs = { lock_version: inquiry_update_params[:lock_version] }
        attrs[:status] = inquiry_update_params[:status] if inquiry_update_params.key?(:status)
        attrs[:priority] = inquiry_update_params[:priority].presence if inquiry_update_params.key?(:priority)
        attrs[:staff_id] = inquiry_update_params[:staff_id].presence if inquiry_update_params.key?(:staff_id)

        inquiry.update!(attrs)

        if inquiry_update_params.key?(:status) && old_status != inquiry.status
          inquiry.comments.create!(comment_type: "system", staff: nil,
            content: "ステータスが#{old_status}→#{inquiry.status}に変更されました(自動記録)")
        end

        if inquiry_update_params.key?(:priority) && priority_label(old_priority) != priority_label(inquiry.priority)
          inquiry.comments.create!(comment_type: "system", staff: nil,
            content: "優先度が#{priority_label(old_priority)}→#{priority_label(inquiry.priority)}に変更されました(自動記録)")
        end

        if inquiry_update_params.key?(:staff_id) && old_staff&.id != inquiry.staff_id
          inquiry.comments.create!(comment_type: "system", staff: nil,
            content: "担当者が#{old_staff&.name || '未割り当て'}→#{inquiry.staff&.name || '未割り当て'}に変更されました(自動記録)")
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      return render_error(e.record.errors.full_messages.join(" / "))
    rescue ActiveRecord::StaleObjectError
      return render_error("他のスタッフの操作により更新されています。最新の内容を確認してください", status: :conflict)
    end

    render json: inquiry_json(inquiry)
  end

  private

  def inquiry_params
    params.require(:inquiry).permit(:name, :email, :phone, :category, :content)
  end

  def inquiry_update_params
    params.require(:inquiry).permit(:status, :priority, :staff_id, :lock_version)
  end

  def priority_label(value)
    value.presence || "未設定"
  end

  def inquiry_json(inquiry)
    {
      id: inquiry.id,
      name: inquiry.name,
      email: inquiry.email,
      phone: inquiry.phone,
      category: inquiry.category,
      content: inquiry.content,
      status: inquiry.status,
      priority: inquiry.priority,
      lock_version: inquiry.lock_version,
      created_at: inquiry.created_at,
      updated_at: inquiry.updated_at,
      staff: inquiry.staff && { id: inquiry.staff.id, name: inquiry.staff.name }
    }
  end
end
