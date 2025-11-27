# API ドキュメント

## 認証

この API は JWT（JSON Web Token）と AWS Cognito を使用した認証をサポートしています。

### 認証ヘッダー

```
Authorization: Bearer <token>
```

## エンドポイント一覧

### ドキュメント管理

#### ドキュメント一覧取得

```
GET /api/documents/
```

**レスポンス例:**

```json
[
  {
    "id": 1,
    "title": "面接対策ガイド",
    "content": "...",
    "created_at": "2025-11-27T10:00:00Z"
  }
]
```

---

### チャット機能

#### OpenAI API とのチャット

```
POST /api/openai/
```

**リクエストボディ:**

```json
{
  "message": "面接の準備について教えてください",
  "thread_id": "uuid-string"
}
```

**レスポンス例:**

```json
{
  "response": "面接の準備には以下のポイントが重要です...",
  "thread_id": "uuid-string"
}
```

---

### チャット履歴

#### チャット履歴取得

```
GET /api/chat-history/?thread_id=<uuid>
```

**クエリパラメータ:**

- `thread_id` (必須): スレッド ID

**レスポンス例:**

```json
[
  {
    "id": 1,
    "thread_id": "uuid-string",
    "message": "面接の準備について教えてください",
    "role": "user",
    "timestamp": "2025-11-27T10:00:00Z"
  },
  {
    "id": 2,
    "thread_id": "uuid-string",
    "message": "面接の準備には...",
    "role": "assistant",
    "timestamp": "2025-11-27T10:00:05Z"
  }
]
```

---

### スレッド管理

#### 新規スレッド作成

```
POST /api/new-thread/
```

**リクエストボディ:**

```json
{
  "creator": "user_id",
  "first_message": "最初のメッセージ"
}
```

**レスポンス例:**

```json
{
  "thread_id": "uuid-string",
  "creator": "user_id",
  "created_at": "2025-11-27T10:00:00Z"
}
```

#### 全スレッド一覧取得

```
GET /api/all-threads/
```

**レスポンス例:**

```json
[
  {
    "thread_id": "uuid-string",
    "creator": "user_id",
    "summary": "面接対策について",
    "first_message": "面接の準備について教えてください",
    "created_at": "2025-11-27T10:00:00Z",
    "updated_at": "2025-11-27T10:30:00Z"
  }
]
```

#### スレッドサマリー取得

```
GET /api/thread-summary/<thread_id>/
```

**レスポンス例:**

```json
{
  "thread_id": "uuid-string",
  "summary": "面接対策についての相談",
  "message_count": 10
}
```

#### スレッド削除

```
DELETE /api/delete-thread/<thread_id>/
```

**レスポンス例:**

```json
{
  "message": "Thread deleted successfully"
}
```

#### スレッドの最初のメッセージ取得

```
GET /api/first-message/<thread_id>/
```

**レスポンス例:**

```json
{
  "thread_id": "uuid-string",
  "first_message": "面接の準備について教えてください",
  "timestamp": "2025-11-27T10:00:00Z"
}
```

---

## エラーレスポンス

### 400 Bad Request

```json
{
  "error": "Invalid request parameters",
  "details": {
    "field": ["This field is required."]
  }
}
```

### 401 Unauthorized

```json
{
  "error": "Authentication credentials were not provided."
}
```

### 404 Not Found

```json
{
  "error": "Resource not found"
}
```

### 500 Internal Server Error

```json
{
  "error": "Internal server error",
  "message": "An unexpected error occurred"
}
```

---

## レート制限

現在、レート制限は実装されていません。本番環境では適切なレート制限の実装を推奨します。

---

## CORS 設定

開発環境では`http://localhost:3000`からのリクエストを許可しています。

本番環境では`.env.production`の`CORS_DOMAIN`を適切に設定してください。

---

## データモデル

### Thread（スレッド）

| フィールド    | 型       | 説明                  |
| ------------- | -------- | --------------------- |
| thread_id     | UUID     | スレッド ID（主キー） |
| creator       | String   | 作成者 ID             |
| summary       | Text     | スレッドのサマリー    |
| first_message | Text     | 最初のメッセージ      |
| created_at    | DateTime | 作成日時              |
| updated_at    | DateTime | 更新日時              |

### ChatHistory（チャット履歴）

| フィールド | 型       | 説明                     |
| ---------- | -------- | ------------------------ |
| id         | Integer  | ID（主キー）             |
| thread_id  | UUID     | スレッド ID（外部キー）  |
| message    | Text     | メッセージ内容           |
| role       | String   | ロール（user/assistant） |
| timestamp  | DateTime | タイムスタンプ           |

### Document（ドキュメント）

| フィールド | 型       | 説明         |
| ---------- | -------- | ------------ |
| id         | Integer  | ID（主キー） |
| title      | String   | タイトル     |
| content    | Text     | 内容         |
| created_at | DateTime | 作成日時     |
| updated_at | DateTime | 更新日時     |

---

## 使用例

### Python（requests）

```python
import requests

# 新規スレッド作成
response = requests.post(
    'http://127.0.0.1:8000/api/new-thread/',
    json={'creator': 'user123', 'first_message': 'こんにちは'},
    headers={'Authorization': 'Bearer <token>'}
)
thread_id = response.json()['thread_id']

# チャット送信
response = requests.post(
    'http://127.0.0.1:8000/api/openai/',
    json={'message': '面接対策を教えて', 'thread_id': thread_id},
    headers={'Authorization': 'Bearer <token>'}
)
print(response.json()['response'])
```

### JavaScript（fetch）

```javascript
// 新規スレッド作成
const createThread = async () => {
  const response = await fetch("http://127.0.0.1:8000/api/new-thread/", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer <token>",
    },
    body: JSON.stringify({
      creator: "user123",
      first_message: "こんにちは",
    }),
  });
  const data = await response.json();
  return data.thread_id;
};

// チャット送信
const sendMessage = async (threadId, message) => {
  const response = await fetch("http://127.0.0.1:8000/api/openai/", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer <token>",
    },
    body: JSON.stringify({
      message: message,
      thread_id: threadId,
    }),
  });
  const data = await response.json();
  return data.response;
};
```

### cURL

```bash
# 新規スレッド作成
curl -X POST http://127.0.0.1:8000/api/new-thread/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"creator": "user123", "first_message": "こんにちは"}'

# チャット送信
curl -X POST http://127.0.0.1:8000/api/openai/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"message": "面接対策を教えて", "thread_id": "uuid-string"}'
```
