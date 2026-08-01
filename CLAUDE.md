# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# 問い合わせ管理アプリ 開発ルール

> このファイルに定義されたルールは Claude Code が**必ず守る**規約です。
> 例外なく適用し、違反する操作は行わないでください。
> タスク管理アプリ(初級編)のCLAUDE.mdを踏襲している。

---

## 1. ワークフロー（開発の手順）

すべての作業は以下の順序で進めること：

1. GitHub に Issue を作成する
2. Issue 番号をもとにブランチを作成する
3. ブランチ上で実装を行う（こまめにコミットしてよい）
4. プッシュ前にブラウザで動作確認する
5. プッシュを行う
6. PR を作成して main へマージする
7. Issue を閉じる

---

## 2. Issue（必須）

- **作業開始前に必ず Issue を作成すること**
- タイトル形式：`[種別] 内容`
  - 例：`[feat] 問い合わせ一覧APIを実装する`
- 種別一覧：

  | 種別 | 用途 |
  |------|------|
  | feat | 新機能の追加 |
  | fix | バグ修正 |
  | docs | ドキュメントの変更 |
  | refactor | リファクタリング |
  | test | テストの追加・修正 |
  | chore | ビルド・設定・雑務 |

---

## 3. ブランチ命名規則

- **形式**：`{種別}/#{Issue番号}-{内容（英語・ケバブケース）}`
- 例：
  - `feature/#12-add-inquiry-list`
  - `fix/#34-fix-login-error`
  - `docs/#5-update-readme`
- 種別は Issue の種別と同じものを使う
- `feature` は `feat` ではなく `feature` を使う

---

## 4. main への直接 push 禁止

- **main ブランチへの直接 push は絶対に禁止**
- 必ずブランチを切って作業し、PR 経由でマージすること
- **変更の種類に関わらず例外はない**（アプリのコード・CLAUDE.md・ドキュメントすべて同じフローで行うこと）

### すべての変更に適用するフロー

```
Issue作成 → ブランチ作成 → 実装・コミット・プッシュ → PR確認 → マージ
```

---

## 5. PR（プルリクエスト）必須

- main へのマージは**必ず PR を通して**行うこと
- PR タイトル形式：`[種別] 内容 (#Issue番号)`
  - 例：`[feat] 問い合わせ一覧APIを実装する (#12)`
- PR 本文に以下を記載すること：
  - 関連 Issue（例：`Closes #12`）
  - 変更内容（箇条書き）
  - 確認手順

---

## 6. コミットメッセージ規則

- **形式**：`{種別}: {内容（日本語）}`
- 例：
  - `feat: 問い合わせ一覧取得APIを実装する`
  - `fix: ログイン時のエラーを修正する`
  - `docs: READMEにセットアップ手順を追記する`
- 種別は Issue・ブランチと同じものを使う
- 内容は日本語で書くこと
- 1行目は体言止めではなく「〜する」形で書くこと

---

## 7. ポート番号ルール

開発環境で使用するポート番号は以下に固定すること：

| サービス | ポート番号 | 備考 |
|---------|-----------|------|
| フロントエンド（Vite） | **5173** | Vite デフォルト |
| バックエンド（Ruby on Rails） | **3000** | Rails デフォルト |
| データベース（MySQL） | **3306** | MySQL デフォルト |

- 他のアプリとポートが衝突する場合は必ず確認すること
- ポート番号を変更する場合は関連する設定ファイルをすべて更新すること

---

## 8. 開発環境の起動コマンド

### 前提

- Ruby は `rbenv` で管理する。バージョンは `backend/.ruby-version`(3.4.10)を参照
- 初回のみ `cd backend && bundle install` を実行する
- フロントエンドは未実装(実装後にこのセクションへコマンドを追記する)

### 全サービス起動手順（毎回この順序で）

```bash
# 1. DB 起動（リポジトリルートで実行）
docker compose up -d

# 2. バックエンド起動
cd backend
bin/rails server
```

- バックエンドの動作確認：`http://localhost:3000/up` にアクセスし、200 OK(緑色の画面)が表示されることを確認する
- フロントエンド起動コマンド・確認URLは、frontend実装後にこのセクションへ追記する

### 案内時のルール

- 起動手順・ブラウザ確認が必要な場面では、**必ず毎回**以下を両方提示すること
  1. 必要なターミナルコマンド（DB → バックエンド → フロントエンドの順）
  2. ブラウザで確認するURL（例：`http://localhost:5173`）
- コマンドやURLを省略してはいけない

---

## 9. PR作成前の確認ルール

- 実装が完了したら、内容を確認してから PR を作成すること
- 確認なしに自動で PR を作成してはいけない
- Issue作成・ブランチ作成・コミット・プッシュ自体は確認なしで進めてよい

---

## 10. アーキテクチャ概要（実装開始後に整備）

```
inquiry-management/
├── backend/            # Ruby on Rails API（ポート 3000、Rails 8.1 / Ruby 3.4.10）
│   └── config/database.yml  # MySQL接続設定（docker-composeのDBに接続）
├── frontend/           # Vue.js + TypeScript（ポート 5173、未実装）
├── docker-compose.yml  # MySQL（ポート 3306）
├── docs/               # 要件・設計ドキュメント
└── terraform/          # AWSインフラ構成（EC2 + RDS、未実装）
```

- `backend/` は `rails new backend --api --database=mysql` により作成した、API専用モードのRailsアプリ
- staffs / inquiries / comments の migration・モデル・APIエンドポイントは未実装(次のIssueで対応)
- 実装が進み次第、バックエンド層構成・フロントエンド構成・APIエンドポイント一覧をこのセクションに追記する

---

## 11. インフラ構成（AWS）

- タスク管理アプリ(初級編)と同一のインフラ構成(EC2: t3.micro、RDS: db.t4g.micro、Terraformで管理)を使用する
- 詳細は [`docs/aws-infrastructure.md`](docs/aws-infrastructure.md) を参照すること
