# テスト環境ではデフォルトで無効化する(既存のcreate系テストが1分間に5回を超えて
# POST /inquiries を叩くため、常時有効だと誤ってスロットリングされてしまう)。
# レート制限自体を検証するテストでは、その中だけ明示的に有効化する。
Rack::Attack.enabled = !Rails.env.test?

Rack::Attack.throttle("inquiries/ip", limit: 5, period: 1.minute) do |req|
  req.ip if req.path == "/inquiries" && req.post?
end

Rack::Attack.throttled_responder = lambda do |_request|
  [
    429,
    { "Content-Type" => "application/json" },
    [ { error: "リクエストが多すぎます。しばらくしてから再度お試しください" }.to_json ]
  ]
end
