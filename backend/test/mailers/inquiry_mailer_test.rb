require "test_helper"

class InquiryMailerTest < ActionMailer::TestCase
  test "confirmation" do
    inquiry = Inquiry.new(
      name: "山田太郎",
      email: "yamada@example.com",
      category: "不具合",
      content: "画面が表示されません",
      created_at: Time.current
    )

    mail = InquiryMailer.confirmation(inquiry)

    assert_equal [ "yamada@example.com" ], mail.to
    assert_equal "【お問い合わせ窓口】お問い合わせを受け付けました", mail.subject
    assert_match "山田太郎", mail.text_part.decoded
    assert_match "画面が表示されません", mail.text_part.decoded
    assert_match "山田太郎", mail.html_part.decoded
    assert_match "画面が表示されません", mail.html_part.decoded
  end
end
