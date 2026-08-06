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

  test "未ログインでも問い合わせを登録できる" do
    post inquiries_url, params: { inquiry: valid_inquiry_params }

    assert_response :created
    assert_not_nil JSON.parse(response.body)["id"]
  end

  test "有効な問い合わせを登録するとDBに保存される" do
    assert_difference "Inquiry.count", 1 do
      post inquiries_url, params: { inquiry: valid_inquiry_params }
    end
  end

  test "問い合わせ登録時に受付済みのシステムコメントが自動作成される" do
    post inquiries_url, params: { inquiry: valid_inquiry_params }

    comments = Inquiry.last.comments
    assert_equal 1, comments.count
    assert_equal "system", comments.first.comment_type
    assert_nil comments.first.staff_id
    assert_equal "問い合わせを受け付けました", comments.first.content
  end

  test "必須項目が空だと422になり日本語のエラーメッセージが返る" do
    assert_no_difference "Inquiry.count" do
      post inquiries_url, params: { inquiry: valid_inquiry_params.merge(name: "") }
    end

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["error"], "氏名を入力してください"
  end

  test "メールアドレスの形式が不正だと422になる" do
    assert_no_difference "Inquiry.count" do
      post inquiries_url, params: { inquiry: valid_inquiry_params.merge(email: "invalid-email") }
    end

    assert_response :unprocessable_entity
  end

  test "不正なカテゴリだと422になる" do
    assert_no_difference "Inquiry.count" do
      post inquiries_url, params: { inquiry: valid_inquiry_params.merge(category: "不正なカテゴリ") }
    end

    assert_response :unprocessable_entity
  end

  test "緊急性を示すキーワードを含む内容だと優先度が「高」になる" do
    post inquiries_url, params: { inquiry: valid_inquiry_params.merge(content: "至急対応をお願いします") }

    assert_equal "高", Inquiry.last.priority
  end

  test "苦情キーワードを含む内容だと優先度が「高」になる" do
    post inquiries_url, params: { inquiry: valid_inquiry_params.merge(content: "クレームです") }

    assert_equal "高", Inquiry.last.priority
  end

  test "深刻な状態を示すキーワードを含む内容だと優先度が「高」になる" do
    post inquiries_url, params: { inquiry: valid_inquiry_params.merge(content: "ログインできない状態です") }

    assert_equal "高", Inquiry.last.priority
  end

  test "「対応してほしい」のような通常の要望表現では優先度は自動で上がらない" do
    post inquiries_url, params: { inquiry: valid_inquiry_params.merge(content: "対応してほしいです") }

    assert_equal "未設定", Inquiry.last.priority
  end

  test "キーワード検出で優先度が自動設定された場合、その旨のシステムコメントが追加される" do
    post inquiries_url, params: { inquiry: valid_inquiry_params.merge(content: "至急対応をお願いします") }

    comments = Inquiry.last.comments.order(:id)
    assert_equal 2, comments.count
    assert_equal "キーワード検出により優先度を「高」に自動設定しました", comments.second.content
  end

  test "キーワードを含まない場合は優先度自動設定のシステムコメントは追加されない" do
    post inquiries_url, params: { inquiry: valid_inquiry_params }

    assert_equal 1, Inquiry.last.comments.count
  end

  test "問い合わせ登録時に確認メールがキューイングされる" do
    assert_enqueued_emails 1 do
      post inquiries_url, params: { inquiry: valid_inquiry_params }
    end
  end

  private

  def log_in_as(staff)
    post session_url, params: { email: staff.email, password: "secret" }
    assert_response :success
  end

  def valid_inquiry_params
    {
      name: "山田太郎",
      email: "yamada@example.com",
      phone: "090-1234-5678",
      category: "不具合",
      content: "画面が表示されません"
    }
  end
end
