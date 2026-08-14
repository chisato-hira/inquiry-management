class InquiryMailer < ApplicationMailer
  # フロントエンド(frontend/src/utils/categoryColors.ts)のカテゴリ配色と揃えている
  CATEGORY_COLORS = {
    "料金プラン" => "#2a78d6",
    "使い方" => "#eb6834",
    "解約" => "#1baf7a",
    "不具合" => "#eda100",
    "その他" => "#e87ba4"
  }.freeze

  def confirmation(inquiry)
    @inquiry = inquiry
    @category_color = CATEGORY_COLORS.fetch(inquiry.category, "#64748b")
    mail(to: @inquiry.email, subject: "【お問い合わせ窓口】お問い合わせを受け付けました")
  end
end
