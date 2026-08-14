---
name: quality-check
description: このリポジトリ(inquiry-management)のバックエンド/フロントエンド実装に対する品質チェックを行うときに使う。ユーザーが「品質チェックして」「品質チェック」「quality check」などと言ったら起動する。lint/型チェック/テスト/セキュリティスキャンの実行、docs/配下のドキュメント(要件定義書・機能要件定義書・画面設計書・データベース設計書)との実装差分の照合、エラー隠蔽(rescue/catchでの握りつぶし)の有無確認、CI等の自動化設定の実態確認までを一貫して行う。
---

# 品質チェック(quality-check)

このスキルは 2026-08-05 に実施したレビューの基準を再現するためのものです(2026-08-14 に再実施・内容を更新)。
「品質チェックして」の一言で、以下の①〜⑤を毎回すべて実施すること。
どれか一つでも省略した場合は、省略した旨と理由を明示すること。

## 前提: rbenvの罠

Bashツールの非対話シェルでは `rbenv init` が実行されないため、`bundle`/`bin/rails`/`rubocop`/`brakeman` 等をそのまま実行するとmacOS標準のシステムRuby(2.6系)にフォールバックしてエラーになる。
backend配下でRuby関連コマンドを実行する前に、必ず同じコマンドの中で `eval "$(rbenv init -)"` を先に通すこと(shell状態はBash呼び出しごとにリセットされるため、毎回付ける)。

```bash
cd backend && eval "$(rbenv init -)" && <command>
```

## ① 実装上の問題点・デファクトスタンダード逸脱の指摘

コードを読みながら、以下の観点を必ず確認する。見つかった場合は「なぜ問題か」「実害が出るタイミング(例: 本番デプロイ時)」まで添えて報告する。まだ実装されていない機能(Issue履歴・CLAUDE.md・関連docsで「次のIssueで対応」と明記されているもの)を「未実装だから問題」として報告しない。

- 設定ファイルの配置ミス(例: `.github/workflows/*.yml` や `.github/dependabot.yml` がサブディレクトリ(`backend/.github` 等)に置かれていて、リポジトリルートでないため実際には発火しない)
- 環境変数化されていないハードコード値(例: フロントエンドの `API_BASE_URL` が `http://localhost:3000` 固定、バックエンドCORSの許可originが `http://localhost:5173` 固定など。本番AWS環境(`docs/aws-infrastructure.md`)へのデプロイ時に破綻する)
- セッションCookie認証を使っているのにCSRF対策(`protect_from_forgery`相当)が入っていない、など標準的なRailsのセキュリティプラクティスからの逸脱(現状GET中心で実害がなくても、書き込み系エンドポイントが増える前に指摘する)
- CLAUDE.mdのセクション10(アーキテクチャ概要)が実装の進行に追従できているか(CLAUDE.md自身が「実装が進み次第追記する」と明記している)
- その他、Rails/Vueのデファクトスタンダードからの逸脱(バリデーション・スコープ・命名規則など)

## ② lint・相当チェックの実行

**フロントエンド** (`frontend/` ディレクトリで実行):

```bash
npx eslint .              # eslint(vue/typescript) — 0件が正常
node_modules/.bin/oxlint . # oxlint — 出力なしが正常
npm run type-check         # vue-tsc --build
npm run test                # vitest run
```

**バックエンド** (`backend/` ディレクトリで、必ず `eval "$(rbenv init -)"` を先に通してから実行):

```bash
bundle exec rubocop                          # スタイル・omakase規約
bundle exec brakeman --no-pager              # セキュリティ静的解析
bundle exec bundler-audit check --update     # 依存gemの既知脆弱性
RAILS_ENV=test bin/rails test                # テスト(DBは docker compose up -d 済みが前提)
```

RuboCopの自動修正可能な指摘は `bundle exec rubocop -a` で直し、直後に再実行して0件になったこと・`bin/rails test` と `brakeman` がグリーンのままであることを確認してから報告する。

## ③ ドキュメントと実装の突合

`docs/requirements.md`・`docs/functional-requirements.md`・`docs/screen-design.md`・`docs/database-design.md` を実装(モデルのバリデーション・スコープ、コントローラのレスポンス形状、フロントエンドの表示項目・ソート挙動・強調表示条件など)と突き合わせる。

- 差分があり、かつ「ドキュメントが正しく実装が間違っている」場合 → ドキュメントを正として実装を修正する
- 差分があり、かつ「実装の方が正しくドキュメントが古いだけ」と判断できる場合 → 修正せず、判断理由を具体的に示して報告する(例: 仕様書にない追加インデックスがあるが実害がなく理にかなっている、等)。ユーザーが同意すればドキュメント側を実態に合わせて更新する(例: Issue #43で追加した「完了」変更時の担当者必須バリデーションをfunctional-requirements.mdに追記した、2026-08-14)
- 未実装機能は差分として扱わない(Issue履歴で計画的にスコープ外とされているもの)
- lint/testの実行結果とドキュメントの記載が食い違う場合(例: テストの期待値と実装の出力が不一致)、`git log -p --follow -- <path>` でその箇所の変更履歴を確認し、「直近の意図的な変更にテスト・ドキュメントが追従していないだけ」か「実装側のバグ」かを切り分けてから判断する。コミットメッセージに明確な意図が書かれていれば前者と判断してよい

## ④ エラー隠蔽の確認(try-catch / rescue)

```bash
grep -rn "rescue" backend/app backend/config
grep -rn "catch" frontend/src
```

見つかった各箇所について、以下のいずれかに該当するかを個別に判定する:

- **問題なし**: 例外がユーザーに表示される(`error.value`・`errorMessage.value` 等)、または「なぜ握りつぶしてよいか」を説明するコメントが付いている(例: 未ログイン判定・ログアウト時のネットワークエラーなど、握りつぶしても実害がない設計上の理由がある場合)
- **問題あり**: 例外を握りつぶした結果、呼び出し元・ユーザー・ログのいずれにもエラーが伝わらず、バグが静かに隠蔽される

「問題あり」に該当する箇所がなければ「なし」と明言して報告し、grepしただけで終わらせない。

## ⑤ 対応方針

①・③で見つかった修正が必要な事項は、CLAUDE.mdのワークフロー(Issue作成→ブランチ作成→実装→動作確認→プッシュ→PR→Issueクローズ)に従う。特に main への直接pushは禁止、コミット/プッシュ前に必ずユーザーに確認する。指摘のみに留めるか実際に修正するかは、事前にユーザーに確認してから進めること。

## 出力の型

①〜④の見出しごとに結果を報告し、最後に「今回のCI/lintの自動化状況は実際にはどうなっているか」(例: ワークフローファイルはあるが発火しない、等)を一言でまとめる。
