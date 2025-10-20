# iOS 푸시 알림 문제 해결 가이드

## ✅ 완료된 수정사항

### 1. iOS Entitlements 파일 생성
- `ios/Runner/Runner.entitlements` 파일 생성
- `aps-environment: production` 설정 추가

### 2. Xcode 프로젝트 설정 업데이트
- 프로젝트 파일에 entitlements 참조 추가
- Debug/Release/Profile 빌드 설정에 entitlements 경로 추가

### 3. AppDelegate.swift 강화
- Firebase 초기화 코드 추가
- 푸시 알림 권한 요청 코드 추가
- MessagingDelegate 구현

## 🔴 Firebase 콘솔에서 확인해야 할 사항

### 1. APNS 인증서/키 설정 확인
1. [Firebase Console](https://console.firebase.google.com) → `kyobodts-mobile` 프로젝트
2. 프로젝트 설정 → 클라우드 메시징 탭
3. iOS 앱 구성에서 APNS 인증서 또는 키가 올바르게 설정되어 있는지 확인

**필요한 설정:**
- **Bundle ID**: `com.kyobodts.mobile`
- **APNS 키** 또는 **APNS 인증서** 업로드 필요

### 2. Apple Developer Console에서 APNS 키 생성 (권장)

**단계별 상세 가이드:**

1. **Apple Developer Console 접속**
   - [https://developer.apple.com/account/resources/authkeys/list](https://developer.apple.com/account/resources/authkeys/list) 접속
   - Apple ID로 로그인

2. **새 키 생성**
   - 우측 상단 **"+"** 버튼 클릭
   - 또는 **"Create a key"** 버튼 클릭

3. **키 이름 입력 (중요)**
   ```
   Key Name: KyoboDTS Mobile APNS
   ```
   **주의사항:**
   - 특수문자(`-`, `_` 등) 사용 금지
   - 영문자, 숫자, 공백만 사용
   - 최대 64자까지 가능

4. **서비스 선택**
   - **"Apple Push Notifications service (APNs)"** 체크박스 선택
   - 다른 서비스는 선택하지 않음

5. **키 생성 완료**
   - **"Continue"** 버튼 클릭
   - **"Register"** 버튼 클릭

6. **키 정보 기록 및 다운로드**
   ```
   Key ID: XXXXXXXXXX (10자리 영숫자)
   Team ID: YYYYYYYYYY (10자리 영숫자)
   ```
   - **Key ID**와 **Team ID**를 메모장에 복사
   - **"Download"** 버튼 클릭하여 `.p8` 파일 다운로드
   - ⚠️ **중요**: 키 파일은 한 번만 다운로드 가능!

7. **파일 확인**
   - 다운로드된 파일명: `AuthKey_XXXXXXXXXX.p8`
   - 파일을 안전한 위치에 보관

### 3. Firebase Console에 APNS 키 업로드

**단계별 상세 가이드:**

1. **Firebase Console 접속**
   - [https://console.firebase.google.com](https://console.firebase.google.com) 접속
   - `kyobodts-mobile` 프로젝트 선택

2. **클라우드 메시징 설정 이동**
   - 좌측 메뉴에서 **"프로젝트 설정"** (톱니바퀴 아이콘) 클릭
   - 상단 탭에서 **"클라우드 메시징"** 클릭

3. **iOS 앱 구성 찾기**
   - 페이지 하단 **"iOS 앱 구성"** 섹션 확인
   - Bundle ID: `com.kyobodts.mobile` 앱 찾기

4. **APNS 키 업로드**
   - **"APNs 인증 키 업로드"** 버튼 클릭
   - 또는 기존 설정이 있다면 **"편집"** 버튼 클릭

5. **키 정보 입력**
   ```
   APNs 인증 키: [다운로드한 .p8 파일 선택]
   키 ID: [Apple Developer에서 복사한 Key ID]
   팀 ID: [Apple Developer에서 복사한 Team ID]
   ```

6. **설정 저장**
   - **"업로드"** 또는 **"저장"** 버튼 클릭
   - 성공 메시지 확인

**Team ID 확인 방법:**
- Apple Developer Console 우측 상단 계정명 옆에 표시
- 또는 [Membership 페이지](https://developer.apple.com/account/#/membership)에서 확인

## 🔧 테스트 방법

### 1. 앱 재빌드 및 설치
```bash
cd /Users/songhyeon-u/dev/kyobodts_mobile
flutter clean
flutter pub get
flutter build ios --release
```

### 2. Firebase 콘솔에서 테스트 메시지 발송
1. Firebase Console → Messaging → 새 캠페인
2. 알림 작성
3. 대상: iOS 앱 선택
4. 예약: 지금 발송

### 3. 푸시 백엔드로 테스트
```bash
curl -X POST http://54.206.1.146:5000/push/send \
  -H "Content-Type: application/json" \
  -d '{
    "title": "iOS 테스트",
    "body": "푸시 알림 테스트",
    "target_type": "topic",
    "target_value": "all_users"
  }'
```

## 🚨 주의사항

1. **개발/배포 환경 구분**
   - 개발: `aps-environment: development`
   - 배포: `aps-environment: production`

2. **Bundle ID 일치 확인**
   - Xcode 프로젝트: `com.kyobodts.mobile`
   - Firebase Console: `com.kyobodts.mobile`
   - Apple Developer: `com.kyobodts.mobile`

3. **인증서 유효성**
   - APNS 키/인증서가 만료되지 않았는지 확인
   - Team ID가 올바른지 확인

## 📱 실제 디바이스 테스트 필수

iOS 푸시 알림은 시뮬레이터에서 작동하지 않습니다.
반드시 실제 iOS 디바이스에서 테스트해야 합니다.