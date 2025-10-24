# 교보DTS 푸시 백엔드 서버

교보DTS 모바일 앱을 위한 Firebase 푸시 메시지 발송 백엔드 서버

## 설치 및 실행

### 1. 의존성 설치
```bash
cd push_backend
pip install -r requirements.txt
```

### 2. Firebase 서비스 계정 키 설정

1. [Firebase Console](https://console.firebase.google.com) → `kyobodts-mobile` 프로젝트
2. 프로젝트 설정 → 서비스 계정 → "새 비공개 키 생성"
3. 다운로드된 JSON 파일의 내용을 `config/service_account_key.json`에 복사

**예시:**
```bash
# Firebase Console에서 다운로드한 파일 내용을 복사
cp ~/Downloads/kyobodts-mobile-xxxxx.json config/service_account_key.json
```

### 3. 서버 실행
```bash
# 서비스 계정 키 설정 확인
ls -la config/service_account_key.json

# 서버 실행
python app.py
```

## API 엔드포인트

### 1. 헬스체크
```bash
GET /health
```

**응답:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00",
  "service": "kyobodts-push-server",
  "firebase_initialized": true
}
```

### 2. 푸시 메시지 발송
```bash
POST /push/send
Content-Type: application/json
```

**요청 예시:**

**단일 토큰 발송:**
```json
{
  "title": "새로운 공지사항",
  "body": "중요한 업데이트가 있습니다",
  "target_type": "token",
  "target_value": "FCM_TOKEN_HERE",
  "action": "show_dynamic_content",
  "content_url": "https://api.company.com/notifications/123",
  "content_type": "dynamic_html"
}
```

**토픽 발송:**
```json
{
  "title": "전체 공지",
  "body": "모든 사용자에게 알림",
  "target_type": "topic",
  "target_value": "all_users"
}
```

**멀티캐스트 발송:**
```json
{
  "title": "그룹 알림",
  "body": "특정 그룹에게 알림",
  "target_type": "tokens",
  "target_value": ["token1", "token2", "token3"]
}
```

**응답:**
```json
{
  "success": true,
  "message": "푸시 메시지가 성공적으로 발송되었습니다",
  "timestamp": "2024-01-01T12:00:00",
  "firebase_response": "projects/kyobodts-mobile/messages/0:1234567890"
}
```

## 확장 가능한 설계

### 푸시 액션 타입
- `show_dynamic_content`: 동적 콘텐츠 모달 표시
- `open_url`: URL 열기
- `show_modal`: 일반 모달 표시
- `navigate_to_screen`: 특정 화면으로 이동

### 콘텐츠 타입
- `dynamic_html`: API에서 가져온 동적 HTML
- `html`: 정적 HTML URL
- `pdf`: PDF 문서
- `asset`: 앱 내 에셋

### 커스텀 데이터 추가
```json
{
  "title": "알림",
  "body": "내용",
  "target_type": "token",
  "target_value": "token",
  "custom_data": {
    "user_id": "12345",
    "notification_id": "67890",
    "priority": "high"
  }
}
```

## 테스트

### cURL 테스트
```bash
# 헬스체크
curl -X GET http://localhost:5000/health

# 푸시 발송
curl -X POST http://54.206.1.146/:5000/push/send \
  -H "Content-Type: application/json" \
  -d '{
    "title": "전체 공지",
    "body": "모든 사용자에게 알림",
    "target_type": "topic",
    "target_value": "all_users"
  }'
```