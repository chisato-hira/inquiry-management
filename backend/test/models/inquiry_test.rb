require "test_helper"

class InquiryTest < ActiveSupport::TestCase
  test "担当者未設定のまま完了にはできない" do
    inquiry = inquiries(:three)
    inquiry.status = "完了"

    assert_not inquiry.valid?
    assert_includes inquiry.errors.full_messages, "担当者が未設定です。担当者を設定すると「完了」に移動できます"
  end

  test "担当者が設定されていれば完了にできる" do
    inquiry = inquiries(:one)
    inquiry.status = "完了"

    assert inquiry.valid?
  end

  test "未対応・対応中は担当者未設定でも変更できる" do
    inquiry = inquiries(:three)

    inquiry.status = "対応中"
    assert inquiry.valid?

    inquiry.status = "未対応"
    assert inquiry.valid?
  end

  test "search: 名前の部分一致でヒットする" do
    assert_includes Inquiry.search("山田"), inquiries(:one)
    assert_not_includes Inquiry.search("山田"), inquiries(:two)
  end

  test "search: メールの部分一致でヒットする" do
    assert_includes Inquiry.search("suzuki"), inquiries(:two)
    assert_not_includes Inquiry.search("suzuki"), inquiries(:one)
  end

  test "search: 問い合わせ内容の部分一致でヒットする" do
    assert_includes Inquiry.search("解約したい"), inquiries(:three)
    assert_not_includes Inquiry.search("解約したい"), inquiries(:one)
  end

  test "search: 空文字/空白のみを渡すと空のリレーションになる" do
    assert_empty Inquiry.search("")
    assert_empty Inquiry.search("   ")
    assert_empty Inquiry.search(nil)
  end

  test "search: LIKEワイルドカード文字を含む検索語は文字通りにマッチする" do
    percent_inquiry = Inquiry.create!(
      name: "割引太郎", email: "percent@example.com", category: "料金プラン",
      content: "割引率90%が適用されませんでした", status: "未対応"
    )
    unrelated_inquiry = Inquiry.create!(
      name: "無関係太郎", email: "unrelated@example.com", category: "料金プラン",
      content: "90 percent unrelated content here", status: "未対応"
    )

    result = Inquiry.search("90%")

    assert_includes result, percent_inquiry
    assert_not_includes result, unrelated_inquiry
  end
end
