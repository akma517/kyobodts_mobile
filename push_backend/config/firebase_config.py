import os
import json
import base64
from typing import Dict, Any

class FirebaseConfig:
    """Firebase 설정 관리"""
    
    # 교보DTS 모바일 프로젝트 정보 (현재 Flutter 프로젝트와 동일)
    PROJECT_ID = "kyobodts-mobile"
    
    @staticmethod
    def get_service_account_config() -> Dict[str, Any]:
        """서비스 계정 설정 반환 (환경변수 우선, 파일 대체)"""
        
        # 1. 환경변수에서 Base64 인코딩된 키 확인
        base64_key = os.getenv('FIREBASE_SERVICE_ACCOUNT_BASE64')
        if base64_key:
            try:
                # Base64 디코딩
                decoded_json = base64.b64decode(base64_key).decode('utf-8')
                service_account_dict = json.loads(decoded_json)
                
                # 프로젝트 ID 검증
                if service_account_dict.get('project_id') != FirebaseConfig.PROJECT_ID:
                    return {
                        "error": f"프로젝트 ID 불일치: {service_account_dict.get('project_id')} != {FirebaseConfig.PROJECT_ID}"
                    }
                
                print("✅ Firebase 서비스 계정 키를 환경변수에서 로드했습니다")
                return {"service_account_dict": service_account_dict}
                
            except Exception as e:
                return {"error": f"환경변수 Base64 키 처리 오류: {str(e)}"}
        
        # 2. 환경변수에서 파일 경로 확인
        env_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH')
        if env_path and os.path.exists(env_path):
            try:
                with open(env_path, 'r', encoding='utf-8') as f:
                    service_account_dict = json.load(f)
                
                # 프로젝트 ID 검증
                if service_account_dict.get('project_id') != FirebaseConfig.PROJECT_ID:
                    return {
                        "error": f"프로젝트 ID 불일치: {service_account_dict.get('project_id')} != {FirebaseConfig.PROJECT_ID}"
                    }
                
                print(f"✅ Firebase 서비스 계정 키를 파일에서 로드했습니다: {env_path}")
                return {"service_account_dict": service_account_dict}
                
            except Exception as e:
                return {"error": f"환경변수 파일 경로 처리 오류: {str(e)}"}
        
        # 3. 기본 파일 경로 확인 (하위 호환성)
        current_dir = os.path.dirname(os.path.abspath(__file__))
        service_account_path = os.path.join(current_dir, 'service_account_key.json')
        
        if os.path.exists(service_account_path):
            try:
                with open(service_account_path, 'r', encoding='utf-8') as f:
                    service_account_dict = json.load(f)
                
                # 프로젝트 ID 검증
                if service_account_dict.get('project_id') != FirebaseConfig.PROJECT_ID:
                    return {
                        "error": f"프로젝트 ID 불일치: {service_account_dict.get('project_id')} != {FirebaseConfig.PROJECT_ID}"
                    }
                
                print(f"✅ Firebase 서비스 계정 키를 기본 파일에서 로드했습니다: {service_account_path}")
                return {"service_account_dict": service_account_dict}
                
            except json.JSONDecodeError as e:
                return {"error": f"JSON 파싱 오류: {str(e)}"}
            except Exception as e:
                return {"error": f"파일 읽기 오류: {str(e)}"}
        
        return {
            "error": "Firebase 서비스 계정 키를 찾을 수 없습니다. 환경변수 FIREBASE_SERVICE_ACCOUNT_BASE64 또는 파일을 확인하세요."
        }
    
    @staticmethod
    def get_firebase_options() -> Dict[str, str]:
        """Firebase 프로젝트 옵션 반환 (Flutter 프로젝트와 동일)"""
        return {
            "android": {
                "apiKey": "AIzaSyAJHDPlvaKoR2FD_t6wyx_mPJYhyFh0guM",
                "appId": "1:860019738433:android:804dc9750e2778a198c3c0",
                "messagingSenderId": "860019738433",
                "projectId": "kyobodts-mobile"
            },
            "ios": {
                "apiKey": "AIzaSyD-Y48wGPTCXBqQQ21jt-0md_g1qtHBtb0",
                "appId": "1:860019738433:ios:29823a1d5f86f09398c3c0",
                "messagingSenderId": "860019738433",
                "projectId": "kyobodts-mobile",
                "iosBundleId": "com.kyobodts.mobile"
            }
        }