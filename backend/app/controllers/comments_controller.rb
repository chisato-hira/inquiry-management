class CommentsController < ApplicationController
  before_action :require_login
  before_action :verify_csrf_token!

  def create
    inquiry = Inquiry.find(params[:inquiry_id])
    comment = inquiry.comments.new(comment_params.merge(comment_type: "manual", staff: current_staff))

    if comment.save
      render json: comment_json(comment), status: :created
    else
      render_error(comment.errors.full_messages.join(" / "))
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end
end
