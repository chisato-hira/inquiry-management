require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "有効なメールアドレスとパスワードでログインできる" do
    post session_url, params: { email: staffs(:one).email, password: "secret" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal staffs(:one).id, body["id"]
    assert_equal staffs(:one).name, body["name"]
  end

  test "パスワードが間違っている場合は401になる" do
    post session_url, params: { email: staffs(:one).email, password: "wrong-password" }

    assert_response :unauthorized
  end

  test "登録されていないメールアドレスの場合は401になる(500にならない)" do
    post session_url, params: { email: "unknown@example.com", password: "secret" }

    assert_response :unauthorized
  end

  test "ログアウトするとセッションが破棄される" do
    post session_url, params: { email: staffs(:one).email, password: "secret" }
    assert_response :success

    delete session_url
    assert_response :no_content

    get session_url
    assert_response :unauthorized
  end

  test "ログイン中はセッション確認APIが現在のスタッフ情報を返す" do
    post session_url, params: { email: staffs(:one).email, password: "secret" }

    get session_url
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal staffs(:one).id, body["id"]
  end

  test "未ログイン状態でのセッション確認APIは401になる" do
    get session_url

    assert_response :unauthorized
  end
end
