# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際にClaude Code (claude.ai/code)にガイダンスを提供します。

## プロジェクト概要

これは家事管理システム用のGraphQL APIとRESTfulエンドポイントを提供するRails 8.0 APIアプリケーション（`izanami-backend`）です。アプリケーションはUUID主キーを持つPostgreSQLを使用し、JWTベースの認証を含んでいます。

## アーキテクチャ

### コアモデル

- **Family**: ユーザーを組織化する中心的なエンティティ（`app/models/family.rb`）
- **User**: ロールベースアクセス（admin/member/guest）と安全なパスワード認証を持つファミリーに属する（`app/models/user.rb`）

### API構造

- **GraphQL API**: `/graphql`のメインインターフェース、開発環境では`/graphiql`でGraphiQLが利用可能
- **REST API**: 認証用の`/api/v1/session`でのセッション管理
- **JWTサービス**: `app/services/jwt/`ディレクトリ内のトークンベース認証

### データベース

- 全テーブルにUUID主キーを持つPostgreSQL
- `deleted_at`タイムスタンプを使用したソフト削除パターン
- ユーザーとファミリー間の外部キー制約

## 開発コマンド

### セットアップ

```bash
bin/setup                    # 完全な開発環境セットアップ
bundle install              # Ruby依存関係のインストール
bin/rails db:prepare         # データベースセットアップとマイグレーション実行
```

### 開発サーバー

```bash
bin/dev                      # 開発サーバー起動（ポート3001）
docker-compose up            # Dockerで実行（アプリ3001、DB5432）
```

### テスト

```bash
bundle exec rspec            # 全テスト実行
bundle exec rspec spec/path/to/specific_spec.rb  # 特定のテスト実行
```

### コード品質

```bash
bin/rubocop                  # リンター実行（rails-omakase設定を使用）
bin/brakeman                 # セキュリティ脆弱性スキャン
```

### データベース操作

```bash
bin/rails db:migrate         # 保留中のマイグレーション実行
bin/rails db:seed            # シードデータ読み込み
bin/rails db:reset           # ドロップ、作成、マイグレート、シード
```

## 開発環境

### Dockerセットアップ

アプリケーションにはDocker設定が含まれています：

- アプリコンテナ: `izanami_backend_app`（ポート3001）
- データベースコンテナ: `izanami_backend_db`（PostgreSQL、ポート5432）
- デフォルト認証情報: `izanami:password@localhost:5432/izanami_backend_development`

### GraphQL開発

- スキーマファイル: `app/graphql/izanami_backend_schema.rb`
- タイプ: `app/graphql/types/`
- 開発環境では`http://localhost:3001/graphiql`でGraphiQLにアクセス

### 主要ディレクトリ

- `app/graphql/` - GraphQLスキーマ、タイプ、リゾルバー
- `app/services/jwt/` - JWT認証サービス
- `app/controllers/api/v1/` - REST APIコントローラー
- `spec/` - FactoryBotファクトリーを使用するRSpecテスト
- `db/seeds/` - 環境固有のシードデータ
