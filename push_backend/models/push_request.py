from dataclasses import dataclass
from typing import Optional, Dict, Any, List, Union
from datetime import datetime

@dataclass
class PushRequest:
    """푸시 메시지 요청 데이터 모델"""
    
    # 필수 필드
    title: str
    body: str
    target_type: str  # 'token', 'topic', 'tokens'
    target_value: Union[str, List[str]]  # FCM 토큰, 토픽명, 또는 토큰 리스트
    
    # 선택 필드 (확장 가능)
    action: Optional[str] = None  # 'show_dynamic_content', 'open_url' 등
    content_url: Optional[str] = None  # 동적 콘텐츠 URL
    content_type: Optional[str] = None  # 'dynamic_html', 'pdf', 'html' 등
    custom_data: Optional[Dict[str, str]] = None  # 추가 커스텀 데이터
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'PushRequest':
        """딕셔너리에서 PushRequest 객체 생성"""
        return cls(
            title=data.get('title', ''),
            body=data.get('body', ''),
            target_type=data.get('target_type', 'token'),
            target_value=data.get('target_value', ''),
            action=data.get('action'),
            content_url=data.get('content_url'),
            content_type=data.get('content_type'),
            custom_data=data.get('custom_data')
        )
    
    def validate(self) -> Optional[str]:
        """요청 데이터 검증"""
        if not self.title:
            return "title은 필수 항목입니다"
        
        if not self.body:
            return "body는 필수 항목입니다"
        
        if not self.target_type:
            return "target_type은 필수 항목입니다"
        
        if self.target_type not in ['token', 'topic', 'tokens']:
            return "target_type은 'token', 'topic', 'tokens' 중 하나여야 합니다"
        
        if not self.target_value:
            return "target_value는 필수 항목입니다"
        
        if self.target_type == 'tokens' and not isinstance(self.target_value, list):
            return "target_type이 'tokens'인 경우 target_value는 리스트여야 합니다"
        
        if self.target_type in ['token', 'topic'] and not isinstance(self.target_value, str):
            return "target_type이 'token' 또는 'topic'인 경우 target_value는 문자열이어야 합니다"
        
        return None

@dataclass
class PushResponse:
    """푸시 메시지 응답 데이터 모델"""
    
    success: bool
    message: str
    timestamp: str
    firebase_response: Optional[Any] = None
    error: Optional[str] = None
    
    @classmethod
    def create_success(cls, message: str, firebase_response: Any = None) -> 'PushResponse':
        """성공 응답 생성"""
        return cls(
            success=True,
            message=message,
            timestamp=datetime.now().isoformat(),
            firebase_response=firebase_response
        )
    
    @classmethod
    def create_error(cls, error_message: str) -> 'PushResponse':
        """에러 응답 생성"""
        return cls(
            success=False,
            message="푸시 발송 실패",
            timestamp=datetime.now().isoformat(),
            error=error_message
        )

# 확장 가능한 푸시 타입 정의
class PushActionType:
    SHOW_DYNAMIC_CONTENT = "show_dynamic_content"
    OPEN_URL = "open_url"
    SHOW_MODAL = "show_modal"
    NAVIGATE_TO_SCREEN = "navigate_to_screen"

class PushContentType:
    DYNAMIC_HTML = "dynamic_html"
    STATIC_HTML = "html"
    PDF = "pdf"
    ASSET = "asset"