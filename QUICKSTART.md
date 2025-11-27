# クイックスタートガイド

このガイドでは、最短で AI 面接コーチ β の開発環境を立ち上げる手順を説明します。

## 必要なもの

- Python 3.11 以上
- Docker
- Git

## 5 分でセットアップ

### 1. リポジトリのクローンと移動

```bash
git clone <repository-url>
cd rag_sample_django
```

### 2. 仮想環境の作成と依存関係のインストール

```bash
python -m venv .venv
source .venv/bin/activate  # macOS/Linux
pip install -r requirements.txt
```

### 3. 環境変数の設定

```bash
cp .env.sample .env.development
```

`.env.development`を編集して、最低限以下を設定：

```env
# 必須項目（開発環境用のダミー値でOK）
SECRET_KEY='your-secret-key-here'
DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1

# データベース（ローカル用）
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASSWORD=your_secure_password
DB_HOST=localhost

# CORS
CORS_DOMAIN=http://localhost:3000

# Azure設定（後で設定可能）
OPENAI_API_KEY=dummy
OPENAI_RESOURCE_NAME=dummy
API_KEY=dummy
SEARCH_SERVICE=dummy
INDEX=dummy
COGNITO_DOMAIN=dummy
COGNITO_CLIENT_ID=dummy
COGNITO_USER_POOL_ID=dummy
```

### 4. MySQL の起動（Docker）

```bash
docker run -d \
  --name mysql-dev \
  -e MYSQL_ROOT_PASSWORD=your_root_password \
  -e MYSQL_DATABASE=your_database_name \
  -e MYSQL_USER=your_database_user \
  -e MYSQL_PASSWORD=your_secure_password \
  -p 3306:3306 \
  mysql:8.0
```

15 秒待ってから次へ進みます。

### 5. データベースのセットアップ

```bash
python manage.py migrate
```

### 6. 管理者ユーザーの作成

```bash
python manage.py createsuperuser --username admin --email admin@example.com --noinput
python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); u = User.objects.get(username='admin'); u.set_password('admin123'); u.save()"
```

### 7. 開発サーバーの起動

```bash
python manage.py runserver
```

## 確認

ブラウザで以下にアクセス：

- **API**: http://127.0.0.1:8000/api/documents/
- **管理画面**: http://127.0.0.1:8000/application_admin/
  - ユーザー名: `admin`
  - パスワード: `admin123`

## 次のステップ

- [README.md](README.md) - 詳細なドキュメント
- [docs/API.md](docs/API.md) - API 仕様
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) - 開発ガイド
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - デプロイメントガイド

## トラブルシューティング

### MySQL に接続できない

```bash
# コンテナの状態を確認
docker ps | grep mysql-dev

# 起動していない場合
docker start mysql-dev
```

### ポートが使用中

```bash
# 別のポートで起動
python manage.py runserver 8001
```

### モジュールが見つからない

```bash
# 依存関係を再インストール
pip install -r requirements.txt
```

## 開発環境の停止

```bash
# Djangoサーバー: Ctrl+C

# MySQLコンテナ
docker stop mysql-dev
```

## 開発環境の再起動

```bash
# MySQLコンテナ
docker start mysql-dev

# 仮想環境を有効化
source .venv/bin/activate

# Djangoサーバー
python manage.py runserver
```

## クリーンアップ

開発環境を完全に削除する場合：

```bash
# MySQLコンテナを削除
docker stop mysql-dev
docker rm mysql-dev

# 仮想環境を削除
deactivate
rm -rf .venv
```
