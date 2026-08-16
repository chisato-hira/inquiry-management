# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# デモ用のスタッフアカウント(パスワードが公開コード上に書かれている)・ダミーの
# 問い合わせデータを本番で誤って作成しないよう、開発環境限定にする
return unless Rails.env.development?

staff_seed = [
  { name: "佐藤 花子", email: "sato@example.com", password: "password123" },
  { name: "鈴木 太郎", email: "suzuki@example.com", password: "password123" },
  { name: "高橋 次郎", email: "takahashi@example.com", password: "password123" }
]

staffs = staff_seed.map do |attrs|
  Staff.find_or_create_by!(email: attrs[:email]) do |staff|
    staff.name = attrs[:name]
    staff.password = attrs[:password]
  end
end

# ポートフォリオのデモ画面として不自然に見えないよう、一般的なダミー名(実在の
# 個人情報とは紐づかない、フォームのサンプルでよく使われる名前)のプールから
# 割り当てる。一部に「テスト」「サンプル」等を含む名前も混ぜ、デモデータである
# ことが一見して分かるようにする
CUSTOMER_NAME_SEED = [
  "山田 太郎", "田中 美咲", "伊藤 健一", "渡辺 陽子", "中村 大輔",
  "テスト 花子", "小林 由美", "加藤 誠", "吉田 恵子", "山本 隆",
  "松本 直子", "サンプル 太郎", "井上 亮", "木村 千尋", "林 修",
  "斎藤 綾子", "清水 拓也", "ダミー 花子"
].freeze

# 未対応は「受付から24時間経過で赤枠強調」機能が実際の問い合わせのように見えるよう、
# 経過済み(24時間超)と直近(24時間未満)を混在させる。両グループとも内部では
# 時系列順(古い→新しい)になるよう並べ、デフォルトソートを決定的にする
PENDING_OVERDUE_COUNT = 5
PENDING_RECENT_COUNT = 20
PENDING_TIMESTAMPS =
  Array.new(PENDING_OVERDUE_COUNT) { |i| (96 - i * 5).hours.ago } +
  Array.new(PENDING_RECENT_COUNT) { |i| (22 - i).hours.ago }

# 「対応中」は実際に着手済みであることが詳細モーダルからも伝わるよう、
# 対応履歴(ステータス変更・担当者変更・コメント)を毎回付与する
IN_PROGRESS_COMMENT_SEED = [
  "内容を確認しました。対応します。",
  "お客様に確認事項をご連絡しました。返信待ちです。",
  "現在原因を調査中です。",
  "対応方法を検討しています。"
].freeze

if Inquiry.count.zero?
  # 未対応だけ20件超にして「もっと見る」ページネーションを検証できるようにする
  status_counts = { "未対応" => 25, "対応中" => 12, "完了" => 15 }
  base_time = 5.days.ago
  sequence = 0

  status_counts.each do |status, count|
    count.times do |index|
      sequence += 1
      priority = Inquiry::PRIORITIES[sequence % Inquiry::PRIORITIES.size]
      category = Inquiry::CATEGORIES[sequence % Inquiry::CATEGORIES.size]
      # 「完了」は担当者未設定だとバリデーションで弾かれるため必ず割り当てる
      assignee = status == "完了" || sequence.even? ? staffs.sample : nil
      timestamp = status == "未対応" ? PENDING_TIMESTAMPS[index] : base_time + sequence.minutes

      inquiry = Inquiry.create!(
        name: CUSTOMER_NAME_SEED[(sequence - 1) % CUSTOMER_NAME_SEED.size],
        email: "customer#{sequence}@example.com",
        phone: sequence.even? ? format("090-0000-%04d", sequence) : nil,
        category: category,
        content: "##{sequence} #{category}に関する問い合わせです。",
        status: status,
        priority: priority,
        staff: assignee,
        created_at: timestamp,
        updated_at: timestamp
      )

      if status == "対応中"
        Comment.create!(
          inquiry: inquiry,
          staff: nil,
          comment_type: "system",
          content: "問い合わせを受け付けました",
          created_at: timestamp
        )
        Comment.create!(
          inquiry: inquiry,
          staff: nil,
          comment_type: "system",
          content: "ステータスが未対応→対応中に変更されました(自動記録)",
          created_at: timestamp + 20.minutes
        )
        if assignee
          Comment.create!(
            inquiry: inquiry,
            staff: nil,
            comment_type: "system",
            content: "担当者が未割り当て→#{assignee.name}に変更されました(自動記録)",
            created_at: timestamp + 25.minutes
          )
        end
        Comment.create!(
          inquiry: inquiry,
          staff: assignee || staffs.sample,
          comment_type: "manual",
          content: IN_PROGRESS_COMMENT_SEED[sequence % IN_PROGRESS_COMMENT_SEED.size],
          created_at: timestamp + 40.minutes
        )
        next
      end

      next unless (sequence % 5).zero? # 5件に1件、対応履歴のサンプルを付与する

      Comment.create!(
        inquiry: inquiry,
        staff: nil,
        comment_type: "system",
        content: "問い合わせを受け付けました",
        created_at: timestamp
      )
      Comment.create!(
        inquiry: inquiry,
        staff: staffs.sample,
        comment_type: "manual",
        content: "内容を確認しました。対応します。",
        created_at: timestamp + 30.minutes
      )
    end
  end
end
