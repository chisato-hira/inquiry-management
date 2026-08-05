require "test_helper"

class StaffsControllerTest < ActionDispatch::IntegrationTest
  test "未ログイン状態で一覧取得すると401になる" do
    get staffs_url

    assert_response :unauthorized
  end

  test "ログイン済みなら一覧を取得できる" do
    post session_url, params: { email: staffs(:one).email, password: "secret" }
    assert_response :success

    get staffs_url

    assert_response :success
  end
end
