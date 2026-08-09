require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  test "未ログイン状態で取得すると401になる" do
    get stats_url

    assert_response :unauthorized
  end

  test "ログイン済みなら集計結果を取得できる" do
    log_in_as(staffs(:one))

    get stats_url
    assert_response :success
    body = JSON.parse(response.body)

    assert_equal(
      Inquiry::STATUSES.index_with { |status| Inquiry.where(status: status).count },
      body["status_counts"]
    )
    assert_equal(
      Inquiry::CATEGORIES.index_with { |category| Inquiry.where(category: category).count },
      body["category_counts"]
    )

    expected_staff_counts = Staff.order(:name).map do |staff|
      {
        "staff_id" => staff.id,
        "name" => staff.name,
        "count" => Inquiry.where(staff_id: staff.id, status: %w[未対応 対応中]).count
      }
    end
    expected_staff_counts << {
      "staff_id" => nil,
      "name" => "未割当",
      "count" => Inquiry.where(staff_id: nil, status: %w[未対応 対応中]).count
    }
    assert_equal expected_staff_counts, body["staff_incomplete_counts"]

    # ステータス別合計と担当者別合計が一致すること(未割当の握りつぶし防止)を明示的に検証する
    assert_equal(
      body["status_counts"]["未対応"] + body["status_counts"]["対応中"],
      body["staff_incomplete_counts"].sum { |s| s["count"] }
    )
  end

  private

  def log_in_as(staff)
    post session_url, params: { email: staff.email, password: "secret" }
    assert_response :success
  end
end
