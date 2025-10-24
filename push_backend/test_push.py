#!/usr/bin/env python3
"""
푸시 서버 테스트 스크립트
"""

import requests
import json

# 서버 URL
BASE_URL = "http://localhost:5000"

def test_health_check():
    """헬스체크 테스트"""
    print("=== 헬스체크 테스트 ===")
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"헬스체크 실패: {e}")
        return False

def test_push_send():
    """푸시 발송 테스트"""
    print("\n=== 푸시 발송 테스트 ===")
    
    # 테스트 데이터
    test_data = {
        "title": "테스트 알림",
        "body": "백엔드 서버에서 발송한 테스트 메시지입니다",
        "target_type": "token",
        "target_value": "TEST_TOKEN_REPLACE_WITH_REAL_TOKEN",
        "action": "show_dynamic_content",
        "content_url": "https://www.google.com",
        "content_type": "dynamic_html"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/push/send",
            headers={"Content-Type": "application/json"},
            json=test_data
        )
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"푸시 발송 테스트 실패: {e}")
        return False

def test_invalid_request():
    """잘못된 요청 테스트"""
    print("\n=== 잘못된 요청 테스트 ===")
    
    # 필수 필드 누락 테스트
    invalid_data = {
        "title": "제목만 있는 요청"
        # body, target_type, target_value 누락
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/push/send",
            headers={"Content-Type": "application/json"},
            json=invalid_data
        )
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 400
    except Exception as e:
        print(f"잘못된 요청 테스트 실패: {e}")
        return False

def main():
    """메인 테스트 실행"""
    print("교보DTS 푸시 백엔드 서버 테스트 시작\n")
    
    # 테스트 실행
    health_ok = test_health_check()
    push_ok = test_push_send()
    invalid_ok = test_invalid_request()
    
    # 결과 요약
    print("\n=== 테스트 결과 요약 ===")
    print(f"헬스체크: {'✅ 성공' if health_ok else '❌ 실패'}")
    print(f"푸시 발송: {'✅ 성공' if push_ok else '❌ 실패'}")
    print(f"잘못된 요청: {'✅ 성공' if invalid_ok else '❌ 실패'}")
    
    if health_ok and push_ok and invalid_ok:
        print("\n🎉 모든 테스트 통과!")
    else:
        print("\n⚠️  일부 테스트 실패")
        print("- Firebase 서비스 계정 키가 설정되었는지 확인하세요")
        print("- 서버가 실행 중인지 확인하세요 (python app.py)")

if __name__ == "__main__":
    main()