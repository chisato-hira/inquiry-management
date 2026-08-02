class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def render_error(message, status: :unprocessable_entity)
    render json: { error: message }, status: status
  end
end
