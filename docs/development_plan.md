# 교보DTS 모바일앱 웹뷰 → 네이티브 UI 전환 작업 계획서

## 📋 프로젝트 개요

### 목적
기존 웹뷰 기반 교보DTS 모바일앱을 모바일 친화적인 네이티브 UI로 전환하여 사용자 경험 개선

### 범위
- 웹뷰 화면을 Flutter Material UI로 대체
- Firebase 푸시 알림 기능 유지
- 5가지 테마 시스템 구축
- 백엔드 API 연동 (Mock 템플릿 제공)

## 🎯 작업 목표

### 주요 기능
1. **로그인 시스템** - 자동 로그인 기능 포함
2. **홈 대시보드** - 4개 섹션별 게시글 미리보기
3. **게시글 목록** - 검색 및 페이지네이션
4. **게시글 상세** - 댓글 시스템 포함
5. **테마 시스템** - 5가지 테마 지원

### 기술 스택
- **Frontend**: Flutter 3.35.6, Material UI 3
- **Backend**: 기존 완성된 REST API
- **Push**: Firebase Cloud Messaging
- **Storage**: SharedPreferences

## 🏗️ 아키텍처 설계

### 화면 구조
```
LoginScreen (로그인)
    ↓
HomeScreen (홈 대시보드)
    ├── PostListScreen (게시글 목록)
    └── PostDetailScreen (게시글 상세)
```

### 폴더 구조
```
lib/
├── main.dart
├── models/          # 데이터 모델
├── screens/         # 화면 위젯
├── services/        # API 통신 서비스
├── widgets/         # 공통 위젯
├── themes/          # 테마 관리
└── utils/           # 유틸리티
```

## 📱 화면별 상세 설계

### 1. 로그인 화면 (LoginScreen)
**기능**
- ID/PW 입력 폼
- 자동 로그인 체크박스
- 로그인 정보 저장 (SharedPreferences)

**UI 구성**
- 앱 로고
- 입력 필드 (ID, Password)
- 자동 로그인 체크박스
- 로그인 버튼

### 2. 홈 화면 (HomeScreen)
**기능**
- 4개 섹션별 최근 5개 게시글 표시
- 섹션별 더보기 버튼
- 테마 설정 접근

**섹션 구성**
- 공지사항
- 회사소식
- 디지털에듀
- 사우소식·자유게시판

**게시글 레이아웃**
- 제목, 게시자, 작성일, 댓글수

### 3. 게시글 목록 화면 (PostListScreen)
**기능**
- 섹션별 전체 게시글 목록
- 검색 기능 (제목/제목+내용/게시자)
- 페이지네이션
- 게시글 상세로 이동

**게시글 레이아웃**
- 제목, 첨부파일 아이콘, 게시자, 작성일, 조회수, 댓글수

### 4. 게시글 상세 화면 (PostDetailScreen)
**기능**
- 게시글 상세 내용 표시
- 댓글 목록 및 작성
- 댓글 수정/삭제 (작성자만)

**UI 구성**
- 헤더: 게시자, 게시일, 제목
- 본문: 게시글 내용
- 하단: 댓글 목록 및 작성 폼

## 🎨 테마 시스템

### 지원 테마
1. **딥 블루** (기본)
2. **딥 퍼플**
3. **딥 그린**
4. **다크**
5. **라이트**

### 구현 방식
- ThemeData 기반 테마 관리
- SharedPreferences로 사용자 설정 저장
- Provider 패턴으로 전역 테마 상태 관리

## 🔌 API 연동 설계

### API 엔드포인트
1. `POST /auth/login` - 로그인
2. `GET /posts?section={section}&page={page}&limit={limit}` - 게시글 목록
3. `GET /posts/{postId}` - 게시글 상세

### 서비스 레이어
- **ApiService**: HTTP 통신 담당
- **AuthService**: 인증 관리
- **PostService**: 게시글 관련 API

### Mock 데이터
실제 API 연동 전까지 Mock 데이터로 개발 진행

## 📊 데이터 모델

### User
```dart
class User {
  final String id;
  final String name;
  final String email;
}
```

### Post
```dart
class Post {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final int viewCount;
  final int commentCount;
  final bool hasAttachment;
  final String section;
}
```

### Comment
```dart
class Comment {
  final String id;
  final String postId;
  final String author;
  final String content;
  final DateTime createdAt;
}
```

## 🚀 개발 일정

### Phase 1: 기반 구조 (1일)
- 프로젝트 구조 설정
- 테마 시스템 구축
- Mock API 서비스 구현

### Phase 2: 화면 개발 (2일)
- 로그인 화면 구현
- 홈 화면 구현
- 게시글 목록 화면 구현
- 게시글 상세 화면 구현

### Phase 3: 통합 및 테스트 (1일)
- 화면 간 네비게이션 연결
- Firebase 푸시 알림 통합
- 전체 기능 테스트

## ✅ 완료 기준

### 기능 요구사항
- [ ] 로그인 및 자동 로그인 기능
- [ ] 4개 섹션 홈 대시보드
- [ ] 게시글 목록 및 검색
- [ ] 게시글 상세 및 댓글 시스템
- [ ] 5가지 테마 지원
- [ ] Firebase 푸시 알림 유지

### 품질 요구사항
- [ ] Material Design 3 준수
- [ ] 반응형 레이아웃
- [ ] 에러 핸들링
- [ ] 로딩 상태 표시
- [ ] 사용자 피드백 제공

## 🔧 기술적 고려사항

### 성능 최적화
- ListView.builder 사용으로 메모리 효율성
- 이미지 캐싱 및 지연 로딩
- API 응답 캐싱

### 보안
- 토큰 기반 인증
- 로그인 정보 암호화 저장
- API 통신 HTTPS 사용

### 접근성
- 스크린 리더 지원
- 충분한 터치 영역
- 색상 대비 준수

---

**작성자**: Flutter 개발팀  
**작성일**: 2024년  
**승인자**: [상급자명]