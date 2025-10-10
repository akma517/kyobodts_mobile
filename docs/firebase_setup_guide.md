# 🔥 Firebase 연동 완벽 가이드

## 📋 개요

이 가이드는 교보DTS 모바일 앱에 Firebase를 연동하여 푸시 알림 기능을 활성화하는 전체 과정을 단계별로 안내합니다.

**소요 시간**: 약 30-45분  
**필요한 것**: Google 계정, 인터넷 연결  
**결과**: 실시간 푸시 알림 기능 활성화

---

## 🎯 Firebase란?

Firebase는 Google에서 제공하는 모바일 및 웹 애플리케이션 개발 플랫폼입니다.
- **FCM(Firebase Cloud Messaging)**: 무료 푸시 알림 서비스
- **실시간 데이터베이스**: 실시간 데이터 동기화
- **인증**: 사용자 로그인 관리
- **호스팅**: 웹 앱 배포

우리는 이 중에서 **FCM**만 사용하여 푸시 알림 기능을 구현합니다.

---

## 📝 사전 준비사항

### ✅ 체크리스트
- [ ] Google 계정 (Gmail 계정)
- [ ] 안정적인 인터넷 연결
- [ ] 프로젝트 패키지명 확인: `com.example.kyobodts_mobile`
- [ ] 앱 이름 확인: `교보DTS`

---

## 🚀 1단계: Firebase 프로젝트 생성

### 1.1 Firebase Console 접속
1. 웹 브라우저에서 [Firebase Console](https://console.firebase.google.com/) 접속
2. Google 계정으로 로그인

### 1.2 새 프로젝트 생성
1. **"프로젝트 추가"** 버튼 클릭
2. **프로젝트 이름**: `kyobodts-mobile` 입력
3. **계속** 버튼 클릭
4. **Google 애널리틱스**: 비활성화 (선택사항)
5. **프로젝트 만들기** 클릭
6. 프로젝트 생성 완료까지 대기 (약 1-2분)

### 1.3 프로젝트 대시보드 확인
- 프로젝트가 생성되면 Firebase 대시보드가 표시됩니다
- 좌측 메뉴에서 다양한 Firebase 서비스를 확인할 수 있습니다

---

## 📱 2단계: Android 앱 등록

### 2.1 Android 앱 추가
1. Firebase 대시보드에서 **Android 아이콘** 클릭
2. **Android 패키지 이름**: `com.example.kyobodts_mobile` 입력
3. **앱 닉네임**: `교보DTS Android` 입력 (선택사항)
4. **디버그 서명 인증서 SHA-1**: 비워둠 (나중에 추가 가능)
5. **앱 등록** 클릭

### 2.2 google-services.json 다운로드
1. **google-services.json 다운로드** 버튼 클릭
2. 다운로드된 파일을 다음 위치에 복사:
   ```
   kyobodts_mobile/android/app/google-services.json
   ```

### 2.3 Firebase SDK 추가 (이미 완료됨)
- 우리 프로젝트는 이미 Firebase SDK가 설정되어 있습니다
- **다음** 버튼을 계속 클릭하여 완료

---

## 🍎 3단계: iOS 앱 등록 (선택사항)

### 3.1 iOS 앱 추가
1. Firebase 대시보드에서 **iOS 아이콘** 클릭
2. **iOS 번들 ID**: `com.example.kyobodts-mobile` 입력
3. **앱 닉네임**: `교보DTS iOS` 입력
4. **앱 등록** 클릭

### 3.2 GoogleService-Info.plist 다운로드
1. **GoogleService-Info.plist 다운로드** 버튼 클릭
2. 다운로드된 파일을 다음 위치에 복사:
   ```
   kyobodts_mobile/ios/Runner/GoogleService-Info.plist
   ```

---

## 🔔 4단계: Firebase Cloud Messaging 활성화

### 4.1 FCM 서비스 활성화
1. Firebase Console 좌측 메뉴에서 **Messaging** 클릭
2. **시작하기** 버튼 클릭 (처음 사용하는 경우)
3. FCM이 자동으로 활성화됩니다

### 4.2 서버 키 확인 (푸시 발송용)
1. Firebase Console에서 **프로젝트 설정** (톱니바퀴 아이콘) 클릭
2. **클라우드 메시징** 탭 클릭
3. **서버 키** 복사 및 안전한 곳에 보관
   - 이 키는 나중에 푸시 메시지 발송 시 필요합니다

---

## 🛠️ 5단계: 프로젝트 설정 업데이트

### 5.1 Android 빌드 설정 활성화
`android/app/build.gradle` 파일에서 다음 라인의 주석을 해제:

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // 이 라인 주석 해제
}
```

### 5.2 빌드 및 테스트
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

---

## 🧪 6단계: 푸시 알림 테스트

### 6.1 앱에서 FCM 토큰 확인
1. 앱을 실행합니다
2. 디버그 콘솔에서 FCM 토큰을 확인합니다
3. 토큰을 복사해둡니다 (길고 복잡한 문자열)

### 6.2 Firebase Console에서 테스트 메시지 발송
1. Firebase Console → **Messaging** → **새 캠페인** → **Firebase 알림 메시지**
2. **알림 제목**: `테스트 알림`
3. **알림 텍스트**: `Firebase 연동 테스트입니다`
4. **다음** 클릭
5. **앱 선택**: 등록한 Android 앱 선택
6. **다음** 클릭
7. **지금 게시** 클릭

### 6.3 고급 테스트 (콘텐츠 모달 포함)
Firebase Console → **Messaging** → **새 캠페인** → **Firebase 알림 메시지**에서:

**기본 정보**:
- 제목: `콘텐츠 테스트`
- 텍스트: `HTML 콘텐츠를 표시합니다`

**추가 옵션** → **맞춤 데이터**:
- 키: `content_url`, 값: `https://www.google.com`
- 키: `content_type`, 값: `html`

---

## 🔧 7단계: 고급 설정 (선택사항)

### 7.1 알림 아이콘 설정
Android에서 푸시 알림의 아이콘을 커스터마이즈할 수 있습니다.

### 7.2 알림 채널 설정
Android 8.0 이상에서 알림 채널을 세분화할 수 있습니다.

### 7.3 백그라운드 메시지 처리
앱이 완전히 종료된 상태에서도 메시지를 처리할 수 있습니다.

---

## 🚨 문제 해결

### 자주 발생하는 문제들

**1. google-services.json 파일을 찾을 수 없음**
- 파일 위치 확인: `android/app/google-services.json`
- 파일명 정확성 확인 (대소문자 구분)

**2. 빌드 오류 발생**
```bash
flutter clean
flutter pub get
```
실행 후 다시 빌드

**3. 푸시 알림이 수신되지 않음**
- FCM 토큰이 올바르게 생성되었는지 확인
- 앱이 포그라운드/백그라운드 상태인지 확인
- 디바이스 알림 권한 설정 확인

**4. iOS에서 알림이 오지 않음**
- 실제 디바이스에서 테스트 (시뮬레이터는 푸시 알림 미지원)
- Apple Developer 계정 및 인증서 설정 필요

---

## 📊 성공 확인 체크리스트

### ✅ 연동 완료 확인
- [ ] Firebase 프로젝트 생성 완료
- [ ] Android 앱 등록 완료
- [ ] google-services.json 파일 배치 완료
- [ ] 앱 빌드 성공
- [ ] FCM 토큰 생성 확인
- [ ] 테스트 푸시 알림 수신 성공
- [ ] 콘텐츠 모달 표시 테스트 성공

---

## 🎉 완료!

축하합니다! Firebase 연동이 완료되었습니다.

### 이제 할 수 있는 것들:
- ✅ 실시간 푸시 알림 발송
- ✅ HTML/PDF 콘텐츠 모달 표시
- ✅ 백그라운드 알림 처리
- ✅ 사용자 맞춤 알림 전송

### 다음 단계:
1. **서버 연동**: 백엔드에서 자동으로 푸시 발송
2. **사용자 세분화**: 특정 사용자 그룹에만 알림 발송
3. **알림 분석**: 알림 성과 측정 및 분석

---

## 📞 추가 도움이 필요하다면

- [Firebase 공식 문서](https://firebase.google.com/docs)
- [Flutter Firebase 플러그인 문서](https://firebase.flutter.dev/)
- 프로젝트 내 `docs/firebase_push_implementation.md` 참고

**작성일**: 2024년  
**버전**: 1.0  
**대상**: Firebase 초보자