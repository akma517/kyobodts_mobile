import firebase_admin
from firebase_admin import credentials, messaging
import logging
import os
from typing import Dict, Any

logger = logging.getLogger(__name__)

class FirebasePushService:
    def __init__(self):
        self._initialized = False
        self._initialize_firebase()
    
    def _initialize_firebase(self):
        """Firebase Admin SDK 초기화"""
        try:
            from config.firebase_config import FirebaseConfig
            
            # config 폴더의 서비스 계정 키 로드
            config = FirebaseConfig.get_service_account_config()
            
            if 'error' in config:
                logger.error(f"Firebase 설정 오류: {config['error']}")
                self._initialized = False
                return
            
            if 'service_account_dict' in config:
                # JSON 딕셔너리로 인증서 생성
                cred = credentials.Certificate(config['service_account_dict'])
                logger.info("config/service_account_key.json에서 서비스 계정 키 로드")
            else:
                logger.error("서비스 계정 키를 찾을 수 없습니다")
                self._initialized = False
                return
            
            # Firebase Admin SDK 초기화
            try:
                firebase_admin.initialize_app(cred)
                self._initialized = True
                logger.info("Firebase Admin SDK 초기화 완료")
            except ValueError as e:
                if "already exists" in str(e):
                    # 이미 초기화된 경우
                    self._initialized = True
                    logger.info("Firebase Admin SDK 이미 초기화됨")
                else:
                    raise e
                
        except Exception as e:
            logger.error(f"Firebase 초기화 실패: {e}")
            self._initialized = False
    
    def is_initialized(self) -> bool:
        """Firebase 초기화 상태 확인"""
        return self._initialized
    
    def send_push(self, push_request) -> Dict[str, Any]:
        """푸시 메시지 발송"""
        if not self._initialized:
            return {'success': False, 'error': 'Firebase가 초기화되지 않았습니다'}
        
        try:
            # FCM 메시지 구성
            message = self._build_message(push_request)
            
            # 타겟 타입에 따른 발송
            if push_request.target_type == 'token':
                response = messaging.send(message)
                return {'success': True, 'response': response}
            
            elif push_request.target_type == 'topic':
                message.topic = push_request.target_value
                response = messaging.send(message)
                return {'success': True, 'response': response}
            
            elif push_request.target_type == 'tokens':
                # 멀티캐스트 발송
                multicast_message = messaging.MulticastMessage(
                    notification=message.notification,
                    data=message.data,
                    tokens=push_request.target_value
                )
                response = messaging.send_multicast(multicast_message)
                return {
                    'success': True, 
                    'response': {
                        'success_count': response.success_count,
                        'failure_count': response.failure_count,
                        'responses': [r.message_id if r.success else r.exception for r in response.responses]
                    }
                }
            
            else:
                return {'success': False, 'error': f'지원하지 않는 타겟 타입: {push_request.target_type}'}
                
        except Exception as e:
            logger.error(f"푸시 발송 실패: {e}")
            return {'success': False, 'error': str(e)}
    
    def _build_message(self, push_request) -> messaging.Message:
        """FCM 메시지 객체 생성"""
        # 알림 구성
        notification = messaging.Notification(
            title=push_request.title,
            body=push_request.body
        )
        
        # 데이터 구성 (확장 가능)
        data = {}
        if push_request.action:
            data['action'] = push_request.action
        if push_request.content_url:
            data['content_url'] = push_request.content_url
        if push_request.content_type:
            data['content_type'] = push_request.content_type
        if push_request.custom_data:
            data.update(push_request.custom_data)
        
        # 메시지 생성
        message = messaging.Message(
            notification=notification,
            data=data
        )
        
        # 토큰 설정 (단일 토큰인 경우)
        if push_request.target_type == 'token':
            message.token = push_request.target_value
        
        return message