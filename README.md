# AI 面接コーチ β

Django REST Framework と Azure OpenAI、Azure AI Search を使用した AI 面接コーチアプリケーションのバックエンド API です。

## ドキュメント

- **[クイックスタート](QUICKSTART.md)** - 5 分で開発環境をセットアップ
- **[API 仕様](docs/API.md)** - 全エンドポイントの詳細
- **[開発ガイド](docs/DEVELOPMENT.md)** - 開発フロー、テスト、デバッグ
- **[デプロイメント](docs/DEPLOYMENT.md)** - 本番環境へのデプロイ手順

## 概要

このプロジェクトは、AI 面接コーチングサービスのバックエンド API を提供します。主な機能：

- Azure OpenAI API を使用した AI チャット機能
- Azure AI Search を使用したドキュメント検索
- チャット履歴の管理
- スレッド管理
- AWS Cognito 認証統合

## 技術スタック

- **フレームワーク**: Django 5.1.1, Django REST Framework 3.15.2
- **データベース**: MySQL 8.0
- **認証**: JWT (djangorestframework-simplejwt), AWS Cognito
- **AI/検索**: Azure OpenAI, Azure AI Search
- **その他**: Docker, python-dotenv

## 必要な環境

- Python 3.11 以上
- Docker（ローカル開発用 MySQL）
- Azure OpenAI アカウント
- Azure AI Search アカウント
- AWS Cognito アカウント（認証用）

## 開発環境のセットアップ

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd rag_sample_django
```

### 2. 仮想環境の作成と有効化

```bash
python -m venv .venv
source .venv/bin/activate  # macOS/Linux
# または
.venv\Scripts\activate  # Windows
```

### 3. 依存関係のインストール

```bash
pip install -r requirements.txt
```

### 4. 環境変数の設定

`.env.sample`をコピーして`.env.development`を作成し、必要な値を設定します：

```bash
cp .env.sample .env.development
```

`.env.development`に以下の情報を設定：

```env
# Azure AI Search
API_KEY=<Your Azure AI Search API Key>
SEARCH_SERVICE=<Azure AI Searchのリソース名>
INDEX=<Azure AI Searchのインデックス名>

# Azure OpenAI
OPENAI_API_KEY=<Your Azure OpenAI API Key>
OPENAI_DEPLOYMENT_NAME=<Azure OpenAI Studio Model デプロイ名>
OPENAI_RESOURCE_NAME=<Azure OpenAI エンドポイントのリソース名>
OPENAI_API_VERSION=2024-02-15-preview
OPENAI_MODEL=gpt-4o-mini

# Database (ローカル開発用)
DB_NAME=your_database_name
DB_USER=<Your Name>
DB_PASSWORD=<Your Password>
DB_HOST=localhost
DB_PORT=3306

# CORS設定
CORS_DOMAIN=http://localhost:3000

# AWS Cognito
COGNITO_DOMAIN=<AWS Cognito Domain>
COGNITO_CLIENT_ID=<AWS Cognito User Client ID>
COGNITO_USER_POOL_ID=<AWS Cognito User Pool ID>

# Django設定
DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
SECRET_KEY=<Django SECRET KEY>
```

### 5. ローカル MySQL の起動（Docker 使用）

```bash
docker run -d \
  --name mysql-dev \
  -e MYSQL_ROOT_PASSWORD=<Your Password> \
  -e MYSQL_DATABASE=your_database_name \
  -e MYSQL_USER=<Your Name> \
  -e MYSQL_PASSWORD=<Your Password> \
  -p 3306:3306 \
  mysql:8.0
```

MySQL が起動するまで 15 秒ほど待ちます。

### 6. データベースマイグレーション

```bash
python manage.py migrate
```

### 7. 管理者ユーザーの作成

```bash
python manage.py createsuperuser --username admin --email admin@example.com --noinput
python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); u = User.objects.get(username='admin'); u.set_password('admin123'); u.save()"
```

デフォルトの管理者アカウント：

- ユーザー名: `admin`
- パスワード: `admin123`

### 8. 開発サーバーの起動

```bash
python manage.py runserver
```

サーバーは http://127.0.0.1:8000/ で起動します。

## API エンドポイント

### 管理画面

- `GET /application_admin/` - Django 管理画面

### API

- `GET /api/documents/` - ドキュメント一覧
- `POST /api/openai/` - OpenAI API とのチャット
- `GET /api/chat-history/` - チャット履歴取得
- `POST /api/new-thread/` - 新規スレッド作成
- `GET /api/thread-summary/<thread_id>/` - スレッドサマリー取得
- `GET /api/all-threads/` - 全スレッド一覧
- `DELETE /api/delete-thread/<thread_id>/` - スレッド削除
- `GET /api/first-message/<thread_id>/` - スレッドの最初のメッセージ取得

## テスト

テストの実行：

```bash
python manage.py test
```

カバレッジレポート付きでテスト実行：

```bash
coverage run --source='.' manage.py test
coverage report
coverage html  # htmlcov/index.htmlでHTMLレポート生成
```

## コード品質

### pre-commit フックの設定

```bash
pre-commit install
```

### 手動で pre-commit を実行

```bash
pre-commit run --all-files
```

## Docker

本番環境用の Dockerfile が含まれています：

```bash
docker build -t ai-interview-coach .
docker run -p 8000:8000 --env-file .env.production ai-interview-coach
```

## プロジェクト構成

```
.
├── manage.py                    # Django管理コマンド
├── requirements.txt             # Python依存関係
├── Dockerfile                   # 本番環境用Dockerイメージ
├── .env.development            # 開発環境変数
├── .env.production             # 本番環境変数
├── .env.sample                 # 環境変数サンプル
├── rag_sample_django/          # プロジェクト設定
│   ├── settings.py            # Django設定
│   ├── urls.py                # ルートURLconf
│   └── wsgi.py                # WSGIエントリーポイント
└── rag_sample_app/             # メインアプリケーション
    ├── models.py              # データモデル
    ├── views.py               # APIビュー
    ├── serializers.py         # DRFシリアライザー
    ├── urls.py                # アプリURLconf
    ├── utils.py               # ユーティリティ関数
    └── tests/                 # テストコード
```

## トラブルシューティング

### MySQL に接続できない

1. Docker コンテナが起動しているか確認：

   ```bash
   docker ps | grep mysql-dev
   ```

2. コンテナが停止している場合は起動：

   ```bash
   docker start mysql-dev
   ```

3. `.env.development`の`DB_HOST`が`localhost`になっているか確認

### ALLOWED_HOSTS エラー

`rag_sample_django/settings.py`の`ALLOWED_HOSTS`に接続元のホストが含まれているか確認してください。

### Azure API キーエラー

`.env.development`の Azure 関連の環境変数が正しく設定されているか確認してください。

## ライセンス

[ライセンス情報を記載]

## 貢献

[貢献ガイドラインを記載]
