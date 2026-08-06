require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test "未ログイン状態でコメントを投稿すると401になる" do
    inquiry = inquiries(:one)

    post inquiry_comments_url(inquiry), params: { comment: { content: "確認します" } }

    assert_response :unauthorized
  end

  test "CSRFトークンを送らずに投稿すると422になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    post inquiry_comments_url(inquiry), params: { comment: { content: "確認します" } }

    assert_response :unprocessable_entity
  end

  test "CSRFトークンが不一致だと422になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    post inquiry_comments_url(inquiry),
      params: { comment: { content: "確認します" } },
      headers: { "X-CSRF-Token" => "invalid-token" }

    assert_response :unprocessable_entity
  end

  test "有効なコメントを投稿すると201になりDBに保存される" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    assert_difference "Comment.count", 1 do
      post inquiry_comments_url(inquiry),
        params: { comment: { content: "確認します" } },
        headers: csrf_headers
    end

    assert_response :created
  end

  test "投稿したコメントはcomment_typeがmanualになりログイン中のスタッフが投稿者になる" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    post inquiry_comments_url(inquiry),
      params: { comment: { content: "確認します" } },
      headers: csrf_headers

    comment = Comment.last
    assert_equal "manual", comment.comment_type
    assert_equal staffs(:one).id, comment.staff_id
  end

  test "レスポンスのJSON形状が正しい" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    post inquiry_comments_url(inquiry),
      params: { comment: { content: "確認します" } },
      headers: csrf_headers

    body = JSON.parse(response.body)
    comment = Comment.last

    assert_equal comment.id, body["id"]
    assert_equal "確認します", body["content"]
    assert_equal "manual", body["comment_type"]
    assert_equal staffs(:one).id, body["staff"]["id"]
    assert_equal staffs(:one).name, body["staff"]["name"]
    assert_not_nil body["created_at"]
  end

  test "空のcontentで投稿すると422になりレコードが作られない" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    assert_no_difference "Comment.count" do
      post inquiry_comments_url(inquiry),
        params: { comment: { content: "" } },
        headers: csrf_headers
    end

    assert_response :unprocessable_entity
    assert_equal "内容を入力してください", JSON.parse(response.body)["error"]
  end

  test "存在しない問い合わせIDに投稿すると404になる" do
    log_in_as(staffs(:one))

    post "/inquiries/999999/comments",
      params: { comment: { content: "確認します" } },
      headers: csrf_headers

    assert_response :not_found
  end

  test "comment_typeやstaff_idを指定して投稿しても無視されmanual・ログイン中スタッフとして保存される" do
    log_in_as(staffs(:one))
    inquiry = inquiries(:one)

    post inquiry_comments_url(inquiry),
      params: { comment: { content: "確認します", comment_type: "system", staff_id: staffs(:two).id } },
      headers: csrf_headers

    comment = Comment.last
    assert_equal "manual", comment.comment_type
    assert_equal staffs(:one).id, comment.staff_id
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
end
