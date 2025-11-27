# デプロイメントガイド

## 本番環境へのデプロイ

### 前提条件

- Docker 環境
- MySQL データベース（本番用）
- Azure OpenAI アカウント
- Azure AI Search アカウント
- AWS Cognito アカウント

## 環境変数の設定

`.env.production`ファイルを作成し、本番環境用の設定を行います：

```env
# 本番環境フラグ
ENV=production

# Django設定
DEBUG=False
SECRET_KEY=<強力なランダム文字列>
DJANGO_ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# データベース（本番用）
DB_NAME=<本番DB名>
DB_USER=<本番DBユーザー>
DB_PASSWORD=<強力なパスワード>
DB_HOST=<本番DBホスト>
DB_PORT=3306

# Azure OpenAI
OPENAI_API_KEY=<本番用APIキー>
OPENAI_DEPLOYMENT_NAME=<デプロイ名>
OPENAI_RESOURCE_NAME=<リソース名>
OPENAI_API_VERSION=2024-02-15-preview
OPENAI_MODEL=gpt-4o-mini

# Azure AI Search
API_KEY=<本番用APIキー>
SEARCH_SERVICE=<サービス名>
INDEX=<インデックス名>

# CORS設定
CORS_DOMAIN=https://yourdomain.com

# AWS Cognito
COGNITO_DOMAIN=<Cognitoドメイン>
COGNITO_CLIENT_ID=<クライアントID>
COGNITO_USER_POOL_ID=<ユーザープールID>
```

## Docker を使用したデプロイ

### 1. Docker イメージのビルド

```bash
docker build -t ai-interview-coach:latest .
```

### 2. コンテナの起動

```bash
docker run -d \
  --name ai-interview-coach \
  -p 8000:8000 \
  --env-file .env.production \
  ai-interview-coach:latest
```

### 3. マイグレーションの実行

```bash
docker exec -it ai-interview-coach python manage.py migrate
```

### 4. 静的ファイルの収集

```bash
docker exec -it ai-interview-coach python manage.py collectstatic --noinput
```

### 5. スーパーユーザーの作成

```bash
docker exec -it ai-interview-coach python manage.py createsuperuser
```

## Docker Compose を使用したデプロイ

`docker-compose.yml`を作成：

```yaml
version: "3.8"

services:
  web:
    build: .
    command: gunicorn rag_sample_django.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - static_volume:/app/staticfiles
    ports:
      - "8000:8000"
    env_file:
      - .env.production
    depends_on:
      - db

  db:
    image: mysql:8.0
    volumes:
      - mysql_data:/var/lib/mysql
    environment:
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    ports:
      - "3306:3306"

  nginx:
    image: nginx:alpine
    volumes:
      - static_volume:/app/staticfiles
      - ./nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - web

volumes:
  mysql_data:
  static_volume:
```

起動：

```bash
docker-compose up -d
```

## クラウドプラットフォームへのデプロイ

### AWS ECS

1. ECR にイメージをプッシュ
2. ECS タスク定義を作成
3. ECS サービスを作成
4. RDS（MySQL）を設定
5. Application Load Balancer を設定

### Google Cloud Run

```bash
# イメージをビルド
gcloud builds submit --tag gcr.io/PROJECT_ID/ai-interview-coach

# デプロイ
gcloud run deploy ai-interview-coach \
  --image gcr.io/PROJECT_ID/ai-interview-coach \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --set-env-vars="$(cat .env.production | xargs)"
```

### Azure App Service

```bash
# リソースグループ作成
az group create --name ai-interview-coach-rg --location japaneast

# App Serviceプラン作成
az appservice plan create \
  --name ai-interview-coach-plan \
  --resource-group ai-interview-coach-rg \
  --sku B1 \
  --is-linux

# Webアプリ作成
az webapp create \
  --resource-group ai-interview-coach-rg \
  --plan ai-interview-coach-plan \
  --name ai-interview-coach \
  --deployment-container-image-name ai-interview-coach:latest

# 環境変数設定
az webapp config appsettings set \
  --resource-group ai-interview-coach-rg \
  --name ai-interview-coach \
  --settings @.env.production
```

## Nginx 設定例

`nginx.conf`:

```nginx
upstream django {
    server web:8000;
}

server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /app/staticfiles/;
    }
}
```

## SSL/TLS 設定

Let's Encrypt を使用した無料 SSL 証明書の取得：

```bash
# Certbotのインストール
apt-get update
apt-get install certbot python3-certbot-nginx

# 証明書の取得
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

## データベースバックアップ

### 自動バックアップスクリプト

`backup.sh`:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"
DB_NAME="aimensetsu"

# MySQLバックアップ
docker exec mysql-prod mysqldump -u root -p${DB_PASSWORD} ${DB_NAME} > ${BACKUP_DIR}/backup_${DATE}.sql

# 古いバックアップを削除（30日以上前）
find ${BACKUP_DIR} -name "backup_*.sql" -mtime +30 -delete
```

cron で定期実行：

```bash
# 毎日午前3時にバックアップ
0 3 * * * /path/to/backup.sh
```

## モニタリング

### ヘルスチェックエンドポイント

`urls.py`に追加：

```python
from django.http import JsonResponse

def health_check(request):
    return JsonResponse({"status": "healthy"})

urlpatterns = [
    path("health/", health_check),
    # ...
]
```

### ログ管理

本番環境では適切なログ設定を行います：

```python
# settings.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/var/log/django/app.log',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
```

## セキュリティチェックリスト

- [ ] `DEBUG=False`に設定
- [ ] 強力な`SECRET_KEY`を使用
- [ ] `ALLOWED_HOSTS`を適切に設定
- [ ] HTTPS/SSL 証明書を設定
- [ ] データベースパスワードを強力なものに変更
- [ ] ファイアウォール設定
- [ ] 定期的なセキュリティアップデート
- [ ] レート制限の実装
- [ ] CORS 設定の確認
- [ ] 環境変数の適切な管理

## パフォーマンス最適化

### Gunicorn の設定

```bash
gunicorn rag_sample_django.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers 4 \
  --threads 2 \
  --timeout 60 \
  --access-logfile - \
  --error-logfile -
```

### データベース接続プーリング

`settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'OPTIONS': {
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
            'charset': 'utf8mb4',
        },
        'CONN_MAX_AGE': 600,  # 接続プーリング
    }
}
```

## トラブルシューティング

### コンテナが起動しない

```bash
# ログを確認
docker logs ai-interview-coach

# コンテナに入って確認
docker exec -it ai-interview-coach /bin/bash
```

### データベース接続エラー

- ホスト名、ポート番号を確認
- ファイアウォール設定を確認
- データベースユーザーの権限を確認

### 静的ファイルが表示されない

```bash
# 静的ファイルを再収集
docker exec -it ai-interview-coach python manage.py collectstatic --noinput
```

## ロールバック手順

問題が発生した場合のロールバック：

```bash
# 前のバージョンのイメージに戻す
docker stop ai-interview-coach
docker rm ai-interview-coach
docker run -d --name ai-interview-coach ai-interview-coach:previous-version

# データベースを復元
docker exec -i mysql-prod mysql -u root -p${DB_PASSWORD} ${DB_NAME} < backup_YYYYMMDD_HHMMSS.sql
```
