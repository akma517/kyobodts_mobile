# 📋 푸시 메시지 기능 테스트 가이드

## 🎯 테스트 목표
- Flutter 앱 ↔ Python 백엔드 ↔ Firebase 간 푸시 메시지 전체 플로우 검증
- 토픽 구독/해제 기능 검증
- 동적 콘텐츠 모달 표시 기능 검증

---

## 📝 사전 준비사항

### 1. 환경 요구사항
- ✅ iOS/Android 실제 기기 (시뮬레이터 ❌)
- ✅ Docker 환경 (로컬 또는 AWS)
- ✅ Firebase 프로젝트 설정 완료
- ✅ 네트워크 연결 (기기 ↔ 백엔드 서버)

### 2. 필수 파일 확인
- ✅ `android/app/google-services.json`
- ✅ `ios/Runner/GoogleService-Info.plist`
- ✅ `push_backend/config/service_account_key.json`

---

## 🚀 테스트 실행 계획

### Phase 1: 백엔드 서버 준비 (5-10분)

#### 1-1. Firebase 서비스 계정 키 준비
1. Firebase Console에서 서비스 계정 키 다운로드
2. `push_backend/config/service_account_key.json`에 배치

#### 1-2. 백엔드 실행 방법 선택

**🔥 방법 A: Docker Compose (로컬 개발)**
```bash
cd push_backend
docker-compose up -d
```
- **장점**: 간단한 명령어, 설정 관리 편리
- **단점**: docker-compose 필요

**🌐 방법 B: AWS 배포 (운영 환경)**
```bash
# AWS EC2에서 실행
docker pull your-dockerhub/kyobodts-push-backend
docker run -d \
  --name kyobodts-push-backend \
  -p 5000:5000 \
  -e FIREBASE_SERVICE_ACCOUNT_BASE64="YOUR_BASE64_KEY" \
  --restart unless-stopped \
  your-dockerhub/kyobodts-push-backend
```
- **장점**: 보안 강화, 운영 환경 적합
- **단점**: 초기 설정 복잡

**🔧 방법 C: 기존 Docker 방식**
```bash
cd push_backend
python setup_firebase.py  # 선택사항
docker build -t kyobodts-push-backend .
docker run -p 5000:5000 kyobodts-push-backend
```
- **장점**: 단계별 제어 가능
- **단점**: 보안 취약점 존재

> **💡 추천**: 로컬 테스트는 A, 운영 배포는 B 방식!

#### 1-3. 백엔드 서버 상태 확인
```bash
curl http://localhost:5000/health
# 응답: {"status": "healthy", "firebase": "connected"}
```

### Phase 2: Flutter 앱 실행 (5분)

#### 2-1. 실제 기기에 앱 설치
```bash
# iOS
flutter run -d [iOS_DEVICE_ID] --release

# Android  
flutter run -d [ANDROID_DEVICE_ID] --release
```

#### 2-2. Firebase 초기화 확인
- 앱 실행 후 콘솔 로그 확인
- "🔥 Firebase 전체 초기화 완료!" 메시지 대기

#### 2-3. FCM 토큰 확인
- 디버그 모드: 홈 화면 FCM 토큰 버튼 클릭
- 토큰 복사 (테스트용)

### Phase 3: 기본 푸시 기능 테스트 (15분)

#### 3-1. 개별 토큰 푸시 테스트
```bash
curl -X POST http://localhost:5000/send-push \
  -H "Content-Type: application/json" \
  -d '{
    "title": "개별 푸시 테스트",
    "body": "FCM 토큰으로 직접 발송",
    "target_type": "token",
    "target_value": "FCM_TOKEN_HERE"
  }'
```

**✅ 검증 포인트:**
- [ ] 앱에서 푸시 알림 수신
- [ ] 알림 클릭 시 앱 실행
- [ ] 콘솔에 수신 로그 출력

#### 3-2. 토픽 푸시 테스트 (all_users)
```bash
curl -X POST http://localhost:5000/send-push \
  -H "Content-Type: application/json" \
  -d '{
    "title": "전체 사용자 알림",
    "body": "all_users 토픽 테스트",
    "target_type": "topic", 
    "target_value": "all_users"
  }'
```

**✅ 검증 포인트:**
- [ ] all_users 토픽 구독자에게 푸시 발송
- [ ] 앱에서 정상 수신

### Phase 4: 토글 기능 테스트 (10분)

#### 4-1. 구독 상태 확인
- 실제 계정으로 로그인
- 상단바에 알림 토글 표시 확인
- 초기 상태: 구독 활성화 (🔔)

#### 4-2. 구독 해제 테스트
1. 알림 토글 클릭
2. "소식지 구독을 취소하시겠습니까?" 확인
3. "확인" 클릭
4. 토글 아이콘 변경 확인 (🔕)
5. "알림이 비활성화되었습니다" 메시지 확인

#### 4-3. 구독 해제 상태에서 푸시 테스트
```bash
curl -X POST http://localhost:5000/send-push \
  -H "Content-Type: application/json" \
  -d '{
    "title": "구독 해제 테스트",
    "body": "이 메시지는 수신되지 않아야 함",
    "target_type": "topic",
    "target_value": "all_users"
  }'
```

**✅ 검증 포인트:**
- [ ] 푸시 알림 수신되지 않음 (구독 해제됨)

#### 4-4. 재구독 테스트
1. 알림 토글 클릭 (🔕 상태에서)
2. "소식지 구독을 사용하시겠습니까?" 확인
3. "확인" 클릭
4. 토글 아이콘 변경 확인 (🔔)
5. 위 푸시 테스트 재실행 → 수신 확인

### Phase 5: 동적 콘텐츠 테스트 (15분)

#### 5-1. HTML 콘텐츠 푸시
```bash
curl -X POST http://localhost:5000/send-push \
  -H "Content-Type: application/json" \
  -d '{
    "title": "HTML 콘텐츠 테스트",
    "body": "HTML 모달이 표시됩니다",
    "target_type": "token",
    "target_value": "FCM_TOKEN_HERE",
    "action": "show_dynamic_content",
    "content_url": "assets/html/sample_notification.html",
    "content_type": "html"
  }'
```

**✅ 검증 포인트:**
- [ ] 푸시 수신
- [ ] 클릭 시 HTML 모달 표시
- [ ] 모달 내용 정상 렌더링
- [ ] 닫기 버튼 동작

#### 5-2. 동적 HTML 콘텐츠 푸시
```bash
curl -X POST http://localhost:5000/send-push \
  -H "Content-Type: application/json" \
  -d '{
    "title": "동적 콘텐츠 테스트", 
    "body": "API에서 HTML을 가져옵니다",
    "target_type": "token",
    "target_value": "FCM_TOKEN_HERE",
    "action": "show_dynamic_content",
    "content_url": "https://httpbin.org/html",
    "content_type": "dynamic_html"
  }'
```

**✅ 검증 포인트:**
- [ ] 외부 API에서 HTML 가져오기
- [ ] 모바일 최적화 CSS 적용
- [ ] 전체화면 모달 표시

### Phase 6: 에러 상황 테스트 (10분)

#### 6-1. 네트워크 오류 테스트
- 기기 네트워크 차단 후 토글 클릭
- "알림 설정 변경에 실패했습니다" 메시지 확인

#### 6-2. 잘못된 콘텐츠 URL 테스트
```bash
curl -X POST http://localhost:5000/send-push \
  -H "Content-Type: application/json" \
  -d '{
    "title": "에러 테스트",
    "body": "잘못된 URL 테스트", 
    "target_type": "token",
    "target_value": "FCM_TOKEN_HERE",
    "content_url": "https://invalid-url-test.com/404",
    "content_type": "dynamic_html"
  }'
```

**✅ 검증 포인트:**
- [ ] 에러 처리 정상 동작
- [ ] 사용자에게 적절한 에러 메시지 표시

---

## 📊 테스트 체크리스트

### ✅ 필수 검증 항목
- [ ] Firebase 초기화 성공
- [ ] FCM 토큰 생성 성공  
- [ ] 개별 푸시 발송/수신
- [ ] 토픽 푸시 발송/수신
- [ ] 토글 구독/해제 동작
- [ ] HTML 콘텐츠 모달 표시
- [ ] 동적 콘텐츠 로딩
- [ ] 에러 상황 처리

### ⚠️ 주의사항
- iOS는 반드시 실제 기기에서 테스트
- 백엔드 서버와 기기 간 네트워크 연결 확인
- Firebase 서비스 계정 키 권한 확인
- 푸시 알림 권한 허용 상태 확인

### 🔧 문제 해결
- **토큰 생성 실패**: Firebase 설정 파일 확인
- **푸시 수신 안됨**: 토픽 구독 상태 확인
- **모달 표시 안됨**: 콘텐츠 URL 접근 가능 여부 확인
- **백엔드 연결 실패**: Docker 컨테이너 상태 및 포트 확인

---

## 🎯 예상 테스트 시간: 총 60-65분
- Phase 1: 5-10분 (백엔드 준비)
- Phase 2: 5분 (앱 실행)  
- Phase 3: 15분 (기본 푸시)
- Phase 4: 10분 (토글 기능)
- Phase 5: 15분 (동적 콘텐츠)
- Phase 6: 10분 (에러 테스트)

---

## 📝 테스트 결과 기록

### 테스트 환경
- **날짜**: ___________
- **테스터**: ___________
- **기기**: ___________
- **OS 버전**: ___________
- **앱 버전**: ___________
- **백엔드 환경**: ___________

### 테스트 결과
| Phase | 테스트 항목 | 결과 | 비고 |
|-------|------------|------|------|
| 1 | 백엔드 서버 준비 | ⭕/❌ | |
| 2 | Flutter 앱 실행 | ⭕/❌ | |
| 3 | 기본 푸시 기능 | ⭕/❌ | |
| 4 | 토글 기능 | ⭕/❌ | |
| 5 | 동적 콘텐츠 | ⭕/❌ | |
| 6 | 에러 상황 | ⭕/❌ | |

### 발견된 이슈
1. ___________
2. ___________
3. ___________

### 개선 사항
1. ___________
2. ___________
3. ___________

---

**테스트 완료 후 이 문서를 업데이트하여 결과를 기록해주세요!** 📝