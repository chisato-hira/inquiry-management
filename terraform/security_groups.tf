# ==========================================
# セキュリティグループ(EC2用ファイアウォール)
# ==========================================
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "EC2 security group: SSH and HTTP only"
  vpc_id      = aws_vpc.main.id

  # --- SSHアクセス(22番) 自分のIPのみ ---
  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # --- フロントエンド・API配信(80番/nginx経由) 自分のIPのみ ---
  ingress {
    description = "App via nginx - my IP only"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # --- アウトバウンド(全許可) ---
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}
