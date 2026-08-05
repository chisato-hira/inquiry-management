require "test_helper"

class InquiriesControllerTest < ActionDispatch::IntegrationTest
  test "未ログイン状態で一覧取得すると401になる" do
    get inquiries_url

    assert_response :unauthorized
  end

  test "未ログイン状態で詳細取得すると401になる" do
    get inquiry_url(inquiries(:one))

    assert_response :unauthorized
  end

  test "ログイン済みなら一覧を取得できる" do
    log_in_as(staffs(:one))

    get inquiries_url

    assert_response :success
  end

  test "ログイン済みなら詳細を取得できる" do
    log_in_as(staffs(:one))

    get inquiry_url(inquiries(:one))

    assert_response :success
  end

  private

  def log_in_as(staff)
    post session_url, params: { email: staff.email, password: "secret" }
    assert_response :success
  end
end
