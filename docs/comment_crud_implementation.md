# 댓글 CRUD 기능 구현

## 개요
교보DTS 모바일앱에 댓글 생성, 읽기, 수정, 삭제(CRUD) 기능을 API 명세에 따라 구현했습니다.

## API 명세 매핑

### 1. 댓글 작성 (CREATE)
- **URL**: `https://km.kyobodts.co.kr/bbs/bbsDocReply.do?method=create`
- **Method**: POST
- **Parameters**:
  - `bbsId`: 게시판 ID (Comment 모델의 bbsId)
  - `docNumber`: 게시글 번호 (Comment 모델의 docNumber)
  - `reRegdate`: 작성일시 (YYYYMMDDHHMMSS 형식)
  - `reText`: 댓글 내용

### 2. 댓글 수정 (UPDATE)
- **URL**: `https://km.kyobodts.co.kr/bbs/bbsDocReply.do?method=update&userId={userId}`
- **Method**: POST
- **Parameters**:
  - `bbsId`: 게시판 ID
  - `docNumber`: 게시글 번호
  - `reRegdate`: 수정일시 (YYYYMMDDHHMMSS 형식)
  - `reSeqno`: 댓글 순번 (Comment 모델의 seqno)
  - `reText`: 수정된 댓글 내용
- **Query String**: `userId` (Comment 모델의 userId)

### 3. 댓글 삭제 (DELETE)
- **URL**: `https://km.kyobodts.co.kr/bbs/bbsDocReply.do?method=remove&bbsId={bbsId}&docNumber={docNumber}&reSeqno={reSeqno}&userId={userId}`
- **Method**: GET
- **Query Parameters**:
  - `bbsId`: 게시판 ID
  - `docNumber`: 게시글 번호
  - `reSeqno`: 댓글 순번
  - `userId`: 사용자 ID

## 구현된 파일들

### 1. CommentService (`lib/services/comment_service.dart`)
댓글 CRUD 전용 서비스 클래스:
- `createComment()`: 댓글 작성
- `updateComment()`: 댓글 수정
- `deleteComment()`: 댓글 삭제
- `getComments()`: 댓글 목록 조회 (기존 ApiService 활용)

### 2. PostService 업데이트 (`lib/services/post_service.dart`)
- CommentService 통합
- 댓글 캐시 시스템 추가 (수정/삭제 시 필요한 댓글 정보 저장)
- `addComment()` 메서드에 bbsId 파라미터 추가

### 3. PostDetailScreen 업데이트 (`lib/screens/post_detail_screen.dart`)
- 댓글 작성 시 bbsId 전달
- 댓글 수정/삭제 후 목록 새로고침
- 디버그 모드에서 CRUD 테스트 버튼 추가

## 주요 특징

### 1. 세션 관리
- HTML 응답 감지 시 자동 세션 만료 처리
- SessionManager를 통한 자동 로그인 재시도

### 2. 에러 처리
- API 응답 형식 자동 감지 (JSON/HTML/텍스트)
- 네트워크 오류 및 세션 만료 상황 처리
- 사용자 친화적 에러 메시지 표시

### 3. 사용자 정보 연동
- AuthService를 통한 현재 사용자 정보 자동 설정
- 댓글 작성자 및 사용자 ID 자동 매핑

### 4. 캐시 시스템
- 댓글 정보 캐시를 통한 수정/삭제 작업 최적화
- 메모리 효율적인 댓글 참조 관리

## 테스트 방법

### 1. 디버그 모드 테스트
- PostDetailScreen에서 오렌지색 디버그 버튼 클릭
- 콘솔에서 CRUD 작업 결과 확인

### 2. 실제 사용 테스트
1. 게시글 상세 화면에서 댓글 작성
2. 본인 댓글에 대해 수정/삭제 메뉴 확인
3. 각 작업 후 성공/실패 토스트 메시지 확인

## 데이터 흐름

```
사용자 액션 → PostDetailScreen → PostService → CommentService → API 호출
                     ↓
              UI 업데이트 ← 결과 처리 ← 응답 파싱 ← HTTP 응답
```

## 보안 고려사항

1. **사용자 권한**: 본인이 작성한 댓글만 수정/삭제 가능
2. **세션 검증**: 모든 API 호출에서 세션 상태 자동 확인
3. **입력 검증**: 댓글 내용 공백 및 길이 검증
4. **쿠키 관리**: 안전한 세션 쿠키 전송

## 향후 개선사항

1. **오프라인 지원**: 네트워크 오류 시 로컬 저장 후 재시도
2. **실시간 업데이트**: WebSocket을 통한 실시간 댓글 동기화
3. **대댓글 지원**: 계층형 댓글 구조 지원
4. **첨부파일**: 댓글에 이미지/파일 첨부 기능