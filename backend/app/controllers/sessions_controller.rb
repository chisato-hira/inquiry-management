class SessionsController < ApplicationController
  def create
    staff = Staff.find_by(email: params[:email])

    if staff&.authenticate(params[:password])
      reset_session
      session[:staff_id] = staff.id
      session[:csrf_token] = SecureRandom.hex(32)
      render json: { id: staff.id, name: staff.name, csrf_token: session[:csrf_token] }
    else
      render_error("メールアドレスまたはパスワードが正しくありません", status: :unauthorized)
    end
  end

  def destroy
    reset_session
    head :no_content
  end

  def show
    if current_staff
      session[:csrf_token] ||= SecureRandom.hex(32)
      render json: { id: current_staff.id, name: current_staff.name, csrf_token: session[:csrf_token] }
    else
      render_error("ログインしていません", status: :unauthorized)
    end
  end
end
