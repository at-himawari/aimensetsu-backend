# 開発ガイド

## 開発フロー

### ブランチ戦略

- `main` - 本番環境
- `develop` - 開発環境
- `feature/*` - 機能開発
- `bugfix/*` - バグ修正

### コミット前のチェック

pre-commit フックが自動的に以下をチェックします：

- コードフォーマット
- リンター
- セキュリティスキャン（gitleaks）

## ローカル開発のヒント

### データベースのリセット

開発中にデータベースをリセットしたい場合：

```bash
# MySQLコンテナを停止・削除
docker stop mysql-dev
docker rm mysql-dev

# 新しいコンテナを起動
docker run -d \
  --name mysql-dev \
  -e MYSQL_ROOT_PASSWORD=your_root_password \
  -e MYSQL_DATABASE=your_database_name \
  -e MYSQL_USER=your_database_user \
  -e MYSQL_PASSWORD=your_secure_password \
  -p 3306:3306 \
  mysql:8.0

# マイグレーションを再実行
sleep 15
python manage.py migrate
python manage.py createsuperuser
```

### シェルでのデバッグ

Django シェルを使用してモデルや API をテスト：

```bash
python manage.py shell
```

```python
# 例：ユーザーの確認
from django.contrib.auth import get_user_model
User = get_user_model()
User.objects.all()

# 例：スレッドの確認
from rag_sample_app.models import Thread
Thread.objects.all()
```

### API のテスト

curl を使用した API テスト例：

```bash
# ドキュメント一覧取得
curl http://127.0.0.1:8000/api/documents/

# 新規スレッド作成
curl -X POST http://127.0.0.1:8000/api/new-thread/ \
  -H "Content-Type: application/json" \
  -d '{"creator": "test_user"}'
```

## 環境変数の管理

### 開発環境と本番環境の切り替え

環境変数`ENV`で切り替え：

```bash
# 開発環境（デフォルト）
python manage.py runserver

# 本番環境
ENV=production python manage.py runserver
```

### 必須環境変数

以下の環境変数は必須です：

- `SECRET_KEY` - Django 秘密鍵
- `DEBUG` - デバッグモード（True/False）
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST` - データベース接続情報
- `OPENAI_API_KEY`, `OPENAI_RESOURCE_NAME` - Azure OpenAI 設定
- `API_KEY`, `SEARCH_SERVICE`, `INDEX` - Azure AI Search 設定

## テストの書き方

### ユニットテストの例

```python
from django.test import TestCase
from rag_sample_app.models import Thread

class ThreadModelTest(TestCase):
    def test_create_thread(self):
        thread = Thread.objects.create(
            creator="test_user",
            summary="Test thread"
        )
        self.assertEqual(thread.creator, "test_user")
```

### API テストの例

```python
from rest_framework.test import APITestCase
from rest_framework import status

class DocumentAPITest(APITestCase):
    def test_get_documents(self):
        response = self.client.get('/api/documents/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
```

## デバッグ

### ログの確認

開発サーバーのコンソール出力でログを確認できます。

### Django Debug Toolbar（オプション）

開発時に Debug Toolbar を追加すると便利です：

```bash
pip install django-debug-toolbar
```

`settings.py`に追加：

```python
if DEBUG:
    INSTALLED_APPS += ['debug_toolbar']
    MIDDLEWARE += ['debug_toolbar.middleware.DebugToolbarMiddleware']
    INTERNAL_IPS = ['127.0.0.1']
```

## パフォーマンス最適化

### データベースクエリの最適化

N+1 問題を避けるため、`select_related()`や`prefetch_related()`を使用：

```python
# 悪い例
threads = Thread.objects.all()
for thread in threads:
    print(thread.chathistory_set.all())  # N+1クエリ

# 良い例
threads = Thread.objects.prefetch_related('chathistory_set').all()
for thread in threads:
    print(thread.chathistory_set.all())  # 1クエリ
```

## セキュリティ

### 秘密情報の管理

- `.env`ファイルは絶対にコミットしない
- `.gitignore`に`.env*`が含まれていることを確認
- 本番環境では環境変数を使用

### CORS 設定

開発環境では`http://localhost:3000`を許可していますが、本番環境では適切なドメインを設定してください。

## よくある問題

### ImportError: No module named 'xxx'

依存関係を再インストール：

```bash
pip install -r requirements.txt
```

### マイグレーションエラー

マイグレーションをリセット：

```bash
python manage.py migrate --fake-initial
```

### ポート競合

別のポートで起動：

```bash
python manage.py runserver 8001
```
