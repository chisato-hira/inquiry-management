# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

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

if Inquiry.count.zero?
  # 未対応だけ20件超にして「もっと見る」ページネーションを検証できるようにする
  status_counts = { "未対応" => 25, "対応中" => 12, "完了" => 15 }
  base_time = 5.days.ago
  sequence = 0

  status_counts.each do |status, count|
    count.times do
      sequence += 1
      priority = Inquiry::PRIORITIES[sequence % Inquiry::PRIORITIES.size]
      category = Inquiry::CATEGORIES[sequence % Inquiry::CATEGORIES.size]
      assignee = sequence.even? ? staffs.sample : nil
      timestamp = base_time + sequence.minutes # created_atを厳密に増加させ、デフォルトソートを決定的にする

      inquiry = Inquiry.create!(
        name: "顧客 #{sequence}",
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
