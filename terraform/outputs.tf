# --- EC2のパブリックIP ---
output "ec2_public_ip" {
  description = "EC2のパブリックIPアドレス"
  value       = aws_instance.app.public_ip
}

# --- アプリのアクセスURL(nginx経由のポート80が正式な入口) ---
output "app_url" {
  description = "アプリへのアクセスURL"
  value       = "http://${aws_instance.app.public_ip}"
}

# --- RDSのエンドポイント(接続先ホスト名:ポート) ---
output "rds_endpoint" {
  description = "RDSの接続先エンドポイント"
  value       = aws_db_instance.main.endpoint
}
