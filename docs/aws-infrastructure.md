# AWSインフラ構成

## 1. 方針

前回(タスク管理アプリ)で構築したAWSインフラ(EC2 + RDS + Terraform)と同じ構成(EC2: t3.micro、RDS: db.t4g.micro)を使用する。DBエンジン・アプリケーション実行環境の設定のみ、今回の技術スタック(Ruby on Rails / MySQL)に合わせて変更する。

前回のTerraformコード(`task-management/terraform/`)を土台とし、`.tf`ファイルのみをコピーして新規に`terraform init`から構築する。前回の`.terraform`ディレクトリ・`terraform.tfstate`(前回の実際のAWSリソースと紐づく状態ファイル)はコピーしない。

---

## 2. 構成

```mermaid
graph TD
    subgraph VPC[10.0.0.0/16]
        subgraph Public1a[パブリックサブネット 10.0.1.0/24]
            EC2[EC2: t3.micro<br/>nginx + Rails]
        end
        subgraph Public1c[パブリックサブネット 10.0.2.0/24]
        end
        RDS[(RDS: MySQL<br/>db.t4g.micro)]
    end
    Internet((インターネット)) -->|80番| EC2
    EC2 -->|3306番| RDS
```

| リソース | 内容 |
|---|---|
| VPC | 10.0.0.0/16、パブリックサブネット2つ(前回と同一構成) |
| EC2 | t3.micro(無料枠対象)、nginx + Ruby on Rails |
| RDS | **MySQL**(前回はPostgreSQL)、db.t4g.micro、単一AZ、非公開 |
| セキュリティグループ | SSH(22)/80番は自分のIPのみ許可。RDSは**3306番**(前回は5432番)をEC2のみ許可 |

---

## 3. 前回からの変更点

| ファイル | 変更内容 |
|---|---|
| `variables.tf` | `project_name`のデフォルト値を`inquiry-management`に変更 |
| `rds.tf` | `engine = "postgres"` → `"mysql"`、`engine_version`をMySQL用に変更 |
| `security_groups.tf` | RDS用SGのポートを5432→3306に変更。EC2用SGのアプリケーションポートをRailsのポート(例: 3000番、Rails単体で動かす場合)に応じて調整 |
| `ec2.tf` | user_data内のインストール対象を、Java/SDKMANからRuby(rbenv等)に変更。Node.jsはVue.jsのフロントエンドビルド用に引き続き必要 |
| SSHキー | `~/.ssh/task-management-key.pub`とは別に、`~/.ssh/inquiry-management-key.pub`を新規作成して使用 |

---

## 4. 今回のスコープに含めないもの

| 項目 | 理由 |
|---|---|
| AWS SES等の外部メール送信サービスとの連携 | 追加費用のリスクを考慮し、今回は開発環境でのメール内容プレビュー確認までとし、本番連携は発展課題として扱う |

---

## 5. 無料枠に関する注意事項

- EC2(t3.micro)・RDS(db.t4g.micro、20GB gp3)は、前回同様AWS無料利用枠の対象範囲内で構成する
- 新規の外部サービス(メール配信サービス等)は導入しないため、追加費用が発生する要素はない
- EC2のCPUクレジットは`ec2.tf`で`standard`に固定している。AWSのデフォルトである`unlimited`のままだと、クレジットを使い切った後もベースラインを超えて動作し続け、その超過分が無料枠外の課金対象になる(Rubyのソースビルドのような高負荷処理でクレジットを使い切った際に実際に発生した)

---

## 6. デプロイ時の注意点(実機検証で判明したもの)

前回(task-management)はJavaをSDKMAN経由でビルド済みバイナリとして導入していたのに対し、今回のRuby(rbenv+ruby-build)はソースからのビルドになるため、t3.microの限られたリソースで以下の問題が実際に発生した。`ec2.tf`のuser_dataで対応済みだが、他の言語・構成でEC2上でのビルドを行う場合は同様の問題が起きうるため記録しておく。

- **メモリ不足によるビルド失敗**: t3.micro(メモリ1GB、スワップなし)でRubyをソースビルドすると、OOM Killerがgccのプロセスを強制終了させビルドが失敗する。`user_data`でスワップ領域(2GB)を追加し、ビルドの並列数(`MAKE_OPTS`)を1に制限することで解消した
- **`/tmp`の容量不足によるビルド失敗**: Amazon Linux 2023の`/tmp`はtmpfs(メモリ上、約459MBが上限)で、ディスク自体は空きがあってもビルド中の一時ファイルがここに書き込まれて溢れる。`TMPDIR`をディスク上の`/var/tmp`に変更することで解消した
- **`rsync`が標準で入っていない**: デプロイスクリプト(`scripts/deploy-backend.sh`)でのソース転送は、Amazon Linux 2023に標準で入っていない`rsync`ではなく`tar`+`ssh`を使っている
- **nginx.conf組み込みのデフォルトサーバーブロックとの競合**: Amazon Linux 2023のnginxパッケージは、`conf.d/default.conf`ではなく`nginx.conf`本体に`server_name _;`のデフォルトサーバーブロックを直接含んでいる。`deploy/nginx/inquiry-management.conf`と競合するため、デプロイスクリプトで無効化している
- **本番DBに初回スタッフアカウントが存在しない**: `db/seeds.rb`は`return unless Rails.env.development?`で本番実行を意図的にガードしているため、`db:prepare`だけでは本番にスタッフアカウントが1件も作成されない。初回は以下のように`rails runner`で手動作成する必要がある

  ```bash
  ssh -i ~/.ssh/inquiry-management-key ec2-user@<EC2のIP> "
    cd /opt/app/backend &&
    set -a && source .env.production && set +a &&
    bundle exec rails runner '
      Staff.create!(name: \"担当者名\", email: \"staff@example.com\", password: \"十分な強度のパスワード\")
    '
  "
  ```
