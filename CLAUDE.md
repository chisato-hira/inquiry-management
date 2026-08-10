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
- 初回のみ `cd frontend && npm install` を実行する

### 全サービス起動手順（毎回この順序で）

```bash
# 1. DB 起動（リポジトリルートで実行）
docker compose up -d

# 2. バックエンド起動
cd backend
bin/rails server

# 3. フロントエンド起動（別ターミナル）
cd frontend
npm run dev
```

- バックエンドの動作確認：`http://localhost:3000/up` にアクセスし、200 OK(緑色の画面)が表示されることを確認する
- フロントエンドの動作確認：`http://localhost:5173` にアクセスし、ボード画面（未対応/対応中/完了の3カラム）が表示されることを確認する

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
│   ├── app/models/           # Staff, Inquiry, Comment
│   ├── app/controllers/      # ApplicationController, SessionsController, StaffsController,
│   │                         # InquiriesController, CommentsController, StatsController
│   ├── app/mailers/          # InquiryMailer（開発環境はletter_openerでブラウザプレビュー）
│   └── config/database.yml   # MySQL接続設定（docker-composeのDBに接続）
├── frontend/           # Vue.js + TypeScript + Vite（ポート 5173）
│   └── src/{components,composables,api,types,utils,views}
│       # ログイン画面・問い合わせボード画面（一覧表示、ページネーション、優先度順/受付日時順ソート、
│       # D&Dとプルダウンでのステータス変更、24時間経過強調）・問い合わせ詳細モーダル
│       # （ステータス/優先度/担当者変更、対応履歴・コメント）・顧客向け問い合わせフォーム・
│       # 統計ダッシュボード（ステータス別/カテゴリ別/担当者別集計）を実装済み。
│       # モバイル・タブレット幅にも対応
├── docker-compose.yml  # MySQL（ポート 3306）
├── docs/               # 要件・設計ドキュメント
└── terraform/          # AWSインフラ構成（EC2 + RDS、未実装）
```

- `backend/` は `rails new backend --api --database=mysql` により作成した、API専用モードのRailsアプリ
- staffs / inquiries / comments の migration・モデルは実装済み(Issue #11)
- 参照系API(GET)・書き込み系API(問い合わせ登録・ステータス/優先度/担当者更新・コメント投稿)・
  スタッフ認証(セッションCookie方式)・統計API・確認メール送信(letter_opener)まで一通り実装済み。
  フロントエンドもログイン・ボード・詳細モーダル・顧客向けフォーム・統計ダッシュボードまで実装済み
  (Issue #11〜#48)。インフラ構築(Terraform/AWSデプロイ)は未着手

### APIエンドポイント一覧

| メソッド | パス | 概要 | 認証 |
|---|---|---|---|
| GET | `/inquiries` | 問い合わせ一覧(status絞り込み、sort=priority\|created_at、20件ページネーション) | 必須 |
| GET | `/inquiries/:id` | 問い合わせ詳細(対応履歴・コメントを時系列で含む) | 必須 |
| POST | `/inquiries` | 問い合わせ登録(顧客向け、キーワード検出による優先度自動設定・確認メール送信を含む) | 不要 |
| PATCH | `/inquiries/:id` | ステータス/優先度/担当者の更新(楽観ロック、変更時に自動記録コメントを追加) | 必須 |
| GET | `/staffs` | 担当者ドロップダウン用の一覧(id/nameのみ) | 必須 |
| POST | `/session` | ログイン | 不要 |
| DELETE | `/session` | ログアウト | 必須 |
| GET | `/session` | ログイン中スタッフの確認 | 必須 |
| POST | `/inquiries/:id/comments` | コメント投稿(manual、投稿者はログイン中スタッフに固定) | 必須(CSRF検証あり) |
| GET | `/stats` | 統計ダッシュボード用データ(ステータス別/カテゴリ別/担当者別集計) | 必須 |

実装が進み次第、このセクションを継続して更新する。

---

## 11. インフラ構成（AWS）

- タスク管理アプリ(初級編)と同一のインフラ構成(EC2: t3.micro、RDS: db.t4g.micro、Terraformで管理)を使用する
- 詳細は [`docs/aws-infrastructure.md`](docs/aws-infrastructure.md) を参照すること

---

## 12. Cookieセッションを使うAPIをcurlで検証する場合の注意

- `POST /session`(ログイン)・`DELETE /session`(ログアウト)等、Cookieでセッションを管理するAPIをcurlで連続して検証する場合、**すべてのリクエストで `-b <file> -c <file>` を同じファイル名でセットで指定すること**
- `-c`(Cookie保存)を付け忘れると、サーバーが返した最新のCookie状態(ログアウト後の状態など)が保存されず、正しく動作している処理が「効いていない」ように見える誤検知が起きる
- 誤検知が起きた場合、まずアプリのコードを疑う前に、検証コマンド側(`-b`/`-c`の指定漏れ)を確認すること
