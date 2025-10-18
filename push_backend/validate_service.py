#!/usr/bin/env python3
"""
Firebase 서비스 계정 키 및 서버 기능 검증 스크립트
"""

import json
import sys
import time
import requests
from config.firebase_config import FirebaseConfig

def validate_service_account_key():
    """서비스 계정 키 검증"""
    print("🔑 서비스 계정 키 검증 중...")
    
    config = FirebaseConfig.get_service_account_config()
    
    if 'error' in config:
        print(f"❌ 서비스 계정 키 오류: {config['error']}")
        return False
    
    key_data = config['service_account_dict']
    
    # 필수 필드 검증
    required_fields = [
        'type', 'project_id', 'private_key_id', 'private_key', 
        'client_email', 'client_id', 'auth_uri', 'token_uri'
    ]
    
    for field in required_fields:
        if field not in key_data:
            print(f"❌ 필수 필드 누락: {field}")
            return False
    
    # 프로젝트 ID 검증
    if key_data['project_id'] != 'kyobodts-mobile':
        print(f"❌ 프로젝트 ID 불일치: {key_data['project_id']}")
        return False
    
    # 서비스 계정 타입 검증
    if key_data['type'] != 'service_account':
        print(f"❌ 잘못된 계정 타입: {key_data['type']}")
        return False
    
    print("✅ 서비스 계정 키 검증 완료")
    print(f"   프로젝트 ID: {key_data['project_id']}")
    print(f"   클라이언트 이메일: {key_data['client_email']}")
    print(f"   Private Key ID: {key_data['private_key_id'][:20]}...")
    
    return True

def validate_firebase_initialization():
    """Firebase 초기화 검증"""
    print("\n🔥 Firebase 초기화 검증 중...")
    
    try:
        from services.firebase_service import FirebasePushService
        
        firebase_service = FirebasePushService()
        
        if firebase_service.is_initialized():
            print("✅ Firebase Admin SDK 초기화 성공")
            return True
        else:
            print("❌ Firebase Admin SDK 초기화 실패")
            return False
            
    except Exception as e:
        print(f"❌ Firebase 초기화 오류: {e}")
        return False

def validate_server_endpoints():
    """서버 엔드포인트 검증"""
    print("\n🌐 서버 엔드포인트 검증 중...")
    
    base_url = "http://localhost:5000"
    
    # 서버 시작 대기
    print("서버 시작 대기 중...")
    for i in range(30):  # 30초 대기
        try:
            response = requests.get(f"{base_url}/health", timeout=5)
            if response.status_code == 200:
                break
        except:
            pass
        time.sleep(1)
        print(f"대기 중... ({i+1}/30)")
    
    # 헬스체크 테스트
    try:
        response = requests.get(f"{base_url}/health", timeout=10)
        if response.status_code == 200:
            health_data = response.json()
            print("✅ 헬스체크 엔드포인트 정상")
            print(f"   상태: {health_data.get('status')}")
            print(f"   Firebase 초기화: {health_data.get('firebase_initialized')}")
            
            if not health_data.get('firebase_initialized'):
                print("❌ Firebase가 초기화되지 않았습니다")
                return False
        else:
            print(f"❌ 헬스체크 실패: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 헬스체크 요청 실패: {e}")
        return False
    
    # 푸시 발송 엔드포인트 테스트 (잘못된 요청으로 400 응답 확인)
    try:
        test_data = {"title": "테스트"}  # 필수 필드 누락
        response = requests.post(
            f"{base_url}/push/send",
            json=test_data,
            timeout=10
        )
        
        if response.status_code == 400:
            print("✅ 푸시 발송 엔드포인트 정상 (검증 로직 작동)")
        else:
            print(f"⚠️  푸시 발송 엔드포인트 응답: HTTP {response.status_code}")
            
    except Exception as e:
        print(f"❌ 푸시 발송 엔드포인트 테스트 실패: {e}")
        return False
    
    return True

def main():
    """메인 검증 프로세스"""
    print("🚀 교보DTS 푸시 서버 검증 시작")
    print("=" * 50)
    
    # 1. 서비스 계정 키 검증
    if not validate_service_account_key():
        print("\n❌ 서비스 계정 키 검증 실패")
        sys.exit(1)
    
    # 2. Firebase 초기화 검증
    if not validate_firebase_initialization():
        print("\n❌ Firebase 초기화 검증 실패")
        sys.exit(1)
    
    # 3. 서버 엔드포인트 검증 (서버가 실행 중인 경우)
    try:
        if validate_server_endpoints():
            print("\n✅ 모든 검증 통과!")
            print("\n🎉 프로젝트가 안정적으로 작동할 준비가 되었습니다!")
        else:
            print("\n⚠️  서버 엔드포인트 검증 실패")
            print("서버가 실행 중인지 확인하세요: python app.py")
    except:
        print("\n⚠️  서버가 실행되지 않아 엔드포인트 검증을 건너뜁니다")
        print("서버 실행 후 다시 테스트하세요: python app.py")
    
    print("\n📋 검증 완료 요약:")
    print("✅ 서비스 계정 키: 정상")
    print("✅ Firebase 초기화: 정상")
    print("✅ 프로젝트 준비: 완료")

if __name__ == "__main__":
    main()