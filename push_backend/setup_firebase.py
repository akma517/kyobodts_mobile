#!/usr/bin/env python3
"""
Firebase 서비스 계정 키 설정 도우미 스크립트
"""

import os
import json

def setup_firebase_key():
    """Firebase 서비스 계정 키 설정"""
    print("🔥 Firebase 서비스 계정 키 설정")
    print("=" * 50)
    
    print("\n1. Firebase Console에서 서비스 계정 키 생성:")
    print("   - https://console.firebase.google.com")
    print("   - kyobodts-mobile 프로젝트 선택")
    print("   - 프로젝트 설정 → 서비스 계정")
    print("   - '새 비공개 키 생성' 클릭")
    print("   - JSON 파일 다운로드")
    
    print("\n2. 설정 방법 선택:")
    print("   [1] 파일 경로로 설정")
    print("   [2] JSON 내용 직접 입력")
    
    choice = input("\n선택 (1 또는 2): ").strip()
    
    if choice == "1":
        setup_by_file_path()
    elif choice == "2":
        setup_by_json_content()
    else:
        print("❌ 잘못된 선택입니다.")

def setup_by_file_path():
    """파일 경로로 설정"""
    file_path = input("\n서비스 계정 키 파일 경로를 입력하세요: ").strip()
    
    if not os.path.exists(file_path):
        print(f"❌ 파일을 찾을 수 없습니다: {file_path}")
        return
    
    # 파일 유효성 검증
    try:
        with open(file_path, 'r') as f:
            key_data = json.load(f)
        
        if key_data.get('type') != 'service_account':
            print("❌ 올바른 서비스 계정 키 파일이 아닙니다.")
            return
        
        if key_data.get('project_id') != 'kyobodts-mobile':
            print(f"⚠️  프로젝트 ID가 다릅니다: {key_data.get('project_id')}")
            print("   kyobodts-mobile 프로젝트의 키인지 확인하세요.")
        
        print(f"\n✅ 서비스 계정 키 파일 확인 완료")
        print(f"   프로젝트: {key_data.get('project_id')}")
        print(f"   클라이언트 이메일: {key_data.get('client_email')}")
        
        # 환경변수 설정 명령어 출력
        print(f"\n🔧 환경변수 설정 명령어:")
        print(f"export FIREBASE_SERVICE_ACCOUNT_PATH='{file_path}'")
        
        # .env 파일 생성
        create_env_file(f"FIREBASE_SERVICE_ACCOUNT_PATH={file_path}")
        
    except Exception as e:
        print(f"❌ 파일 읽기 실패: {e}")

def setup_by_json_content():
    """JSON 내용 직접 입력"""
    print("\n서비스 계정 키 JSON 내용을 붙여넣으세요:")
    print("(여러 줄 입력 후 빈 줄에서 Enter)")
    
    lines = []
    while True:
        line = input()
        if line.strip() == "":
            break
        lines.append(line)
    
    json_content = "\n".join(lines)
    
    try:
        key_data = json.loads(json_content)
        
        if key_data.get('type') != 'service_account':
            print("❌ 올바른 서비스 계정 키가 아닙니다.")
            return
        
        if key_data.get('project_id') != 'kyobodts-mobile':
            print(f"⚠️  프로젝트 ID가 다릅니다: {key_data.get('project_id')}")
        
        print(f"\n✅ 서비스 계정 키 확인 완료")
        print(f"   프로젝트: {key_data.get('project_id')}")
        print(f"   클라이언트 이메일: {key_data.get('client_email')}")
        
        # 환경변수 설정 명령어 출력
        json_escaped = json_content.replace('"', '\\"').replace('\n', '')
        print(f"\n🔧 환경변수 설정 명령어:")
        print(f'export FIREBASE_SERVICE_ACCOUNT_JSON=\'{json_escaped}\'')
        
        # .env 파일 생성
        create_env_file(f"FIREBASE_SERVICE_ACCOUNT_JSON={json_escaped}")
        
    except json.JSONDecodeError as e:
        print(f"❌ JSON 파싱 실패: {e}")

def create_env_file(env_content):
    """환경변수 파일 생성"""
    env_file = ".env"
    
    try:
        with open(env_file, 'w') as f:
            f.write(f"# Firebase 서비스 계정 키 설정\n")
            f.write(f"{env_content}\n")
            f.write(f"\n# 서버 설정\n")
            f.write(f"FLASK_ENV=development\n")
            f.write(f"FLASK_DEBUG=True\n")
            f.write(f"PORT=5000\n")
        
        print(f"\n📝 .env 파일이 생성되었습니다.")
        print(f"   다음 명령어로 서버를 실행하세요:")
        print(f"   python app.py")
        
    except Exception as e:
        print(f"❌ .env 파일 생성 실패: {e}")

if __name__ == "__main__":
    setup_firebase_key()