class InquiryMailer < ApplicationMailer
  def confirmation(inquiry)
    @inquiry = inquiry
    mail(to: @inquiry.email, subject: "【問い合わせ管理】お問い合わせを受け付けました")
  end
end
