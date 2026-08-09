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

  test "未ログインで更新すると401になる" do
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry), params: { inquiry: { status: "対応中", lock_version: inquiry.lock_version } }

    assert_response :unauthorized
  end

  test "CSRFトークンを送らずに更新すると422になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry), params: { inquiry: { status: "対応中", lock_version: inquiry.lock_version } }

    assert_response :unprocessable_entity
  end

  test "CSRFトークンが不一致だと422になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry),
      params: { inquiry: { status: "対応中", lock_version: inquiry.lock_version } },
      headers: { "X-CSRF-Token" => "invalid-token" }

    assert_response :unprocessable_entity
  end

  test "ステータスを更新すると値が変わりシステムコメントが追加される" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    assert_difference "inquiry.comments.reload.count", 1 do
      patch inquiry_url(inquiry),
        params: { inquiry: { status: "対応中", lock_version: inquiry.lock_version } },
        headers: csrf_headers

      assert_response :success
    end

    inquiry.reload
    assert_equal "対応中", inquiry.status
    assert_equal "ステータスが未対応→対応中に変更されました(自動記録)", inquiry.comments.order(:id).last.content
  end

  test "優先度を更新すると値が変わりシステムコメントが追加される" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry),
      params: { inquiry: { priority: "高", lock_version: inquiry.lock_version } },
      headers: csrf_headers

    assert_response :success
    inquiry.reload
    assert_equal "高", inquiry.priority
    assert_equal "優先度が未設定→高に変更されました(自動記録)", inquiry.comments.order(:id).last.content
  end

  test "担当者を更新すると値が変わりシステムコメントが追加される" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry),
      params: { inquiry: { staff_id: staffs(:two).id, lock_version: inquiry.lock_version } },
      headers: csrf_headers

    assert_response :success
    inquiry.reload
    assert_equal staffs(:two).id, inquiry.staff_id
    assert_equal "担当者がテスト太郎→テスト花子に変更されました(自動記録)", inquiry.comments.order(:id).last.content
  end

  test "複数項目を同時更新すると複数のシステムコメントが追加される" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    assert_difference "inquiry.comments.reload.count", 2 do
      patch inquiry_url(inquiry),
        params: { inquiry: { status: "対応中", priority: "高", lock_version: inquiry.lock_version } },
        headers: csrf_headers
    end
  end

  test "優先度をnilから「未設定」に送っても意味が同じ場合はシステムコメントが増えない" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:two)
    inquiry.update_columns(priority: nil)

    assert_no_difference "inquiry.comments.reload.count" do
      patch inquiry_url(inquiry),
        params: { inquiry: { priority: "未設定", lock_version: inquiry.lock_version } },
        headers: csrf_headers

      assert_response :success
    end
  end

  test "優先度に空文字を送ると422にならずnil(未設定)として保存される" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry),
      params: { inquiry: { priority: "", lock_version: inquiry.lock_version } },
      headers: csrf_headers

    assert_response :success
    assert_nil inquiry.reload.priority
  end

  test "更新項目が空だと422になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry), params: { inquiry: { lock_version: inquiry.lock_version } }, headers: csrf_headers

    assert_response :unprocessable_entity
  end

  test "lock_versionを含めずに更新すると422になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry), params: { inquiry: { status: "対応中" } }, headers: csrf_headers

    assert_response :unprocessable_entity
  end

  test "存在しない担当者IDを指定すると422になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry),
      params: { inquiry: { staff_id: 999_999, lock_version: inquiry.lock_version } },
      headers: csrf_headers

    assert_response :unprocessable_entity
  end

  test "不正なステータス値を送ると422になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    patch inquiry_url(inquiry),
      params: { inquiry: { status: "不正な値", lock_version: inquiry.lock_version } },
      headers: csrf_headers

    assert_response :unprocessable_entity
  end

  test "担当者未設定のまま完了に更新すると422になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:three)

    patch inquiry_url(inquiry),
      params: { inquiry: { status: "完了", lock_version: inquiry.lock_version } },
      headers: csrf_headers

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_includes body["error"], "担当者が未設定です。担当者を設定すると「完了」に移動できます"
    assert_equal "未対応", inquiry.reload.status
  end

  test "担当者を同時に設定すれば未割当の問い合わせでも完了に更新できる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:three)

    patch inquiry_url(inquiry),
      params: { inquiry: { status: "完了", staff_id: staffs(:one).id, lock_version: inquiry.lock_version } },
      headers: csrf_headers

    assert_response :success
    inquiry.reload
    assert_equal "完了", inquiry.status
    assert_equal staffs(:one).id, inquiry.staff_id
  end

  test "楽観的ロック: 古いlock_versionで更新すると409になりコメントも作られない" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)
    stale_lock_version = inquiry.lock_version

    patch inquiry_url(inquiry),
      params: { inquiry: { status: "対応中", lock_version: stale_lock_version } },
      headers: csrf_headers
    assert_response :success
    assert_equal stale_lock_version + 1, JSON.parse(response.body)["lock_version"]

    assert_no_difference "inquiry.comments.reload.count" do
      patch inquiry_url(inquiry),
        params: { inquiry: { status: "完了", lock_version: stale_lock_version } },
        headers: csrf_headers

      assert_response :conflict
    end
  end

  private

  def log_in_as(staff)
    post session_url, params: { email: staff.email, password: "secret" }
    assert_response :success
    @csrf_token = JSON.parse(response.body)["csrf_token"]
  end

  def csrf_headers
    { "X-CSRF-Token" => @csrf_token }
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
