#!/bin/bash

# 🚀 EC2 환경 설정 스크립트
# 사용법: ./setup_ec2.sh YOUR_DOCKERHUB_USERNAME YOUR_BASE64_KEY
# 
# YOUR_DOCKERHUB_USERNAME: Docker Hub 계정명 (예: john123)
# YOUR_BASE64_KEY: deploy.sh에서 출력된 Base64 인코딩된 Firebase 키

set -e

DOCKERHUB_USERNAME=${1:-"akma517"}
BASE64_KEY=${2:-""}

if [ -z "$BASE64_KEY" ]; then
    echo "❌ 사용법: ./setup_ec2.sh DOCKERHUB_USERNAME BASE64_KEY"
    echo "📝 DOCKERHUB_USERNAME: Docker Hub 계정명 (예: john123)"
    echo "📝 BASE64_KEY: deploy.sh 실행 시 출력된 Base64 키"
    echo "예시: ./setup_ec2.sh john123 eyJ0eXBlIjoi..."
    exit 1
fi

echo "🔧 EC2 환경 설정 시작..."

# 1. .env 파일 생성
echo "📝 환경변수 파일 생성..."
echo "FIREBASE_SERVICE_ACCOUNT_BASE64=$BASE64_KEY" > .env
chmod 600 .env
echo "✅ .env 파일 생성 완료"

# 2. Docker Compose 파일 생성
echo "📝 Docker Compose 파일 생성..."
cat > docker-compose.yml << EOF
version: '3.8'
services:
  push-backend:
    image: $DOCKERHUB_USERNAME/kyobodts-push-backend
    ports:
      - "5000:5000"
    environment:
      - FIREBASE_SERVICE_ACCOUNT_BASE64=\${FIREBASE_SERVICE_ACCOUNT_BASE64}
    restart: unless-stopped
EOF
echo "✅ docker-compose.yml 생성 완료"

# 3. Docker 이미지 다운로드
echo "📦 Docker 이미지 다운로드..."
docker pull $DOCKERHUB_USERNAME/kyobodts-push-backend

# 4. 컨테이너 실행
echo "🚀 컨테이너 실행..."
docker-compose up -d

# 5. 상태 확인
echo "🔍 서비스 상태 확인..."
sleep 5
docker ps
echo ""
echo "🌐 헬스 체크..."
curl -s http://localhost:5000/health || echo "⚠️  헬스 체크 실패 - 잠시 후 다시 시도해주세요"

echo ""
echo "✅ 설정 완료!"
echo "📋 유용한 명령어:"
echo "  - 로그 확인: docker-compose logs -f"
echo "  - 재시작: docker-compose restart"
echo "  - 중지: docker-compose down"
echo "  - 헬스 체크: curl http://localhost:5000/health"