# --- DB Subnet Group(RDSの仕様上、2つ以上のAZのサブネットが必要) ---
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# --- RDS用セキュリティグループ(EC2のセキュリティグループからの3306番のみ許可) ---
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS security group: allow MySQL from EC2 only"
  vpc_id      = aws_vpc.main.id

  # --- MySQL(3306番) EC2からのみ許可(IPではなくセキュリティグループ単位で許可) ---
  ingress {
    description     = "MySQL from EC2 security group only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
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
    Name = "${var.project_name}-rds-sg"
  }
}

# --- RDS本体(MySQL、Single-AZ、公開アクセスなし) ---
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "mysql"
  engine_version = "8.0.46"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false
  publicly_accessible = false

  # 学習用のため、destroy時に最終スナップショットを求めない
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.project_name}-db"
  }
}
