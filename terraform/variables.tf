# --- AWSリージョン(東京) ---
variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

# --- プロジェクト名(リソース名の接頭辞) ---
variable "project_name" {
  description = "プロジェクト名(リソース名のプレフィックスに使用)"
  type        = string
  default     = "inquiry-management"
}

# --- 自分のIP(SSH/80の許可用。必須・0.0.0.0/0にしない) ---
variable "my_ip_cidr" {
  description = "SSH接続を許可する自分のグローバルIP。例: 203.0.113.5/32 (terraform.tfvarsで設定すること)"
  type        = string
}

# --- RDSのデータベース名(backend/config/database.ymlのproduction.primary.databaseと合わせる) ---
variable "db_name" {
  description = "RDSに作成するデータベース名"
  type        = string
  default     = "backend_production"
}

# --- RDSのマスターユーザー名(backend/config/database.ymlのproduction.primary.usernameと合わせる。terraform.tfvarsで設定) ---
variable "db_username" {
  description = "RDSのマスターユーザー名"
  type        = string
}

# --- RDSのマスターパスワード(EC2側でBACKEND_DATABASE_PASSWORD環境変数として設定する値と合わせる。terraform.tfvarsで設定) ---
variable "db_password" {
  description = "RDSのマスターパスワード"
  type        = string
  sensitive   = true
}
