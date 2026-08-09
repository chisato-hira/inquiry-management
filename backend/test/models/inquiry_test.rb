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
end
