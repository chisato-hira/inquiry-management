class InquiriesController < ApplicationController
  before_action :require_login, except: %i[create]

  PER_PAGE = 20

  def index
    scope = Inquiry.includes(:staff)

    if params[:status].present?
      return render_error("invalid status", status: :bad_request) unless Inquiry::STATUSES.include?(params[:status])

      scope = scope.where(status: params[:status])
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

    ActiveRecord::Base.transaction do
      inquiry.comments.create!(comment_type: "system", staff: nil, content: "問い合わせを受け付けました")

      if inquiry.priority_auto_set_by_keyword?
        inquiry.comments.create!(comment_type: "system", staff: nil, content: "キーワード検出により優先度を「高」に自動設定しました")
      end
    end

    InquiryMailer.confirmation(inquiry).deliver_later

    render json: inquiry_json(inquiry), status: :created
  end

  private

  def inquiry_params
    params.require(:inquiry).permit(:name, :email, :phone, :category, :content)
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
      created_at: inquiry.created_at,
      updated_at: inquiry.updated_at,
      staff: inquiry.staff && { id: inquiry.staff.id, name: inquiry.staff.name }
    }
  end

  def comment_json(comment)
    {
      id: comment.id,
      content: comment.content,
      comment_type: comment.comment_type,
      created_at: comment.created_at,
      staff: comment.staff && { id: comment.staff.id, name: comment.staff.name }
    }
  end
end
