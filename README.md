# 교보DTS 모바일앱

플러터를 이용하여 개발한 모바일 앱

## Why?
그룹웨어나 인사시스템이 모바일 네이티브 앱을 지원하지 않아 브라우저로만 접속이 가능한 접근성에 불편함을 느꼈다.

개선되길 기다리기보다 개선하는 쪽을 택했다.

## How?
앱뷰 연동방식으로 그룹웨어와 인사시스템을 연결하고,

개인 디바이스에 로그인정보를 저장하여 자동 로그인을 기능을 지원하도록 적용하였다.

**🔔 NEW: Firebase 푸시 알림 기능 추가**
- 앱 종료/백그라운드 상태에서도 푸시 알림 수신
- 푸시 클릭 시 HTML/PDF 콘텐츠 모달 자동 표시
- 실시간 중요 알림 전달 시스템 구축

## Issuese
1. 웹뷰 라이브러리 중 일부(flutter_webview)는 새창 오픈을 지원하지 않아 flutter_inappwebview 라이브러리를 사용하였다.
2. ios 웹뷰 연동 중 연동된 사이트가 내부적으로 http 통신을 할 경우, 해당 통신을 차단한다. 따라서 이를 허용하도록 ios 설정을 변경해주었다.
     - (info.plist :: NSAppTransportSecurity 추가)
3. dialog 위젯은 setState의 영향을 받지 않는다. 따라서 dialog 위젯을 statefullBuilder 위젯으로 감싸주어 statefull 위젯으로 만들어 줬다.
4. material3 디자인을 적용 시 생각만큼 thema가 컨트롤되지 않는다. 그럼에도 material3 디자인이 예뻐서 적용시켰다.

## screenshots
![Simulator Screenshot - iPhone 15 Pro Max - 2024-02-19 at 00 20 49](https://github.com/akma517/kyobodts_mobile/assets/66403979/dcf5da3f-e319-4419-b5e0-fbc799ee88ee)
![Simulator Screenshot - iPhone 15 Pro Max - 2024-02-18 at 23 59 55](https://github.com/akma517/kyobodts_mobile/assets/66403979/69a8ec5f-9891-448e-aba6-c752a02fbce1)
![Simulator Screenshot - iPhone 15 Pro Max - 2024-02-19 at 00 00 11](https://github.com/akma517/kyobodts_mobile/assets/66403979/eea437e8-068f-4b36-8d53-07da7f82e9f2)
![Simulator Screenshot - iPhone 15 Pro Max - 2024-02-19 at 00 00 33](https://github.com/akma517/kyobodts_mobile/assets/66403979/bd892ca9-a864-4377-9c72-3bcf7b082621)
![Simulator Screenshot - iPhone 15 Pro Max - 2024-02-19 at 00 01 03](https://github.com/akma517/kyobodts_mobile/assets/66403979/e5b9cf5c-5265-4a7b-979d-71d2ee8150b6)
![Simulator Screenshot - iPhone 15 Pro Max - 2024-02-19 at 00 01 13](https://github.com/akma517/kyobodts_mobile/assets/66403979/ec59998c-3a71-40ba-a804-6ffd5522ef18)
![Simulator Screenshot - iPhone 15 Pro Max - 2024-02-19 at 00 01 33 2](https://github.com/akma517/kyobodts_mobile/assets/66403979/9c2e5b48-248f-411f-b797-f0426e65ccf9)

민감정보는 블라인드 처리

---

## 개발 환경 및 라이브러리 버전

### Flutter & Dart 버전
- **Flutter**: 3.35.6
- **Dart SDK**: 3.6.0

### 의존성 라이브러리 (고정 버전)
```yaml
dependencies:
  cupertino_icons: 1.0.8
  flutter_inappwebview: 6.1.5
  shared_preferences: 2.3.2
  url_launcher: 6.3.1
  flutter_launcher_icons: 0.14.1
  flutter_native_splash: 2.4.1
  # Firebase 푸시 알림 관련
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1
  path_provider: ^2.1.4

dev_dependencies:
  flutter_lints: 6.0.0
```

### Android 설정
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 35 (Android 15)
- **Gradle**: 8.10.2
- **Android Gradle Plugin**: 8.7.2
- **Kotlin**: 1.9.25

### 환경 요구사항
- **Dart SDK**: >=3.6.0 <4.0.0
- **Android Studio**: Arctic Fox 이상
- **Xcode**: 13.0 이상 (iOS 개발 시)

### 빌드 명령어
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🔔 Firebase 푸시 알림 기능

### 주요 기능
- **실시간 푸시 알림**: 앱 상태와 관계없이 알림 수신
- **콘텐츠 모달**: HTML/PDF 파일을 전체화면 모달로 표시
- **자동 실행**: 푸시 클릭 시 앱 자동 실행 및 콘텐츠 표시
- **다양한 콘텐츠**: 웹 URL, 로컬 HTML, PDF 문서 지원

### 설정 방법
1. **Firebase 프로젝트 생성**
2. **Android**: `google-services.json` 파일을 `android/app/` 디렉토리에 추가
3. **iOS**: `GoogleService-Info.plist` 파일을 `ios/Runner/` 디렉토리에 추가

### 푸시 메시지 형식
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "알림 제목",
    "body": "알림 내용"
  },
  "data": {
    "content_url": "표시할 콘텐츠 URL",
    "content_type": "html|pdf|asset"
  }
}
```

### 테스트 방법
- 디버그 모드에서 홈 화면의 알림 버튼 클릭
- 샘플 HTML 콘텐츠가 모달로 표시됨

자세한 구현 내용은 [`docs/firebase_push_implementation.md`](docs/firebase_push_implementation.md) 참고