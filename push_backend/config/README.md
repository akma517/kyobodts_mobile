# Firebase 서비스 계정 키 설정

## service_account_key.json 파일 설정

1. [Firebase Console](https://console.firebase.google.com)에 접속
2. `kyobodts-mobile` 프로젝트 선택
3. 프로젝트 설정 → 서비스 계정 탭
4. "새 비공개 키 생성" 클릭
5. 다운로드된 JSON 파일의 내용을 `service_account_key.json`에 복사

## 파일 구조
```
config/
├── firebase_config.py          # Firebase 설정 관리 클래스
├── service_account_key.json    # Firebase 서비스 계정 키 (실제 키로 교체 필요)
└── README.md                   # 이 파일
```

## 주의사항
- `service_account_key.json` 파일의 템플릿 내용을 실제 Firebase 서비스 계정 키로 교체해야 합니다
- 프로젝트 ID가 `kyobodts-mobile`인지 확인하세요
- Private 저장소이므로 키 파일을 안전하게 커밋할 수 있습니다