#!/bin/bash

# 🚀 교보DTS 푸시 백엔드 배포 스크립트 (보안 강화 버전)

set -e  # 에러 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 교보DTS 푸시 백엔드 배포 시작${NC}"

# 1. Firebase 서비스 계정 키 확인
if [ ! -f "config/service_account_key.json" ]; then
    echo -e "${RED}❌ Firebase 서비스 계정 키 파일이 없습니다: config/service_account_key.json${NC}"
    echo -e "${YELLOW}💡 Firebase Console에서 서비스 계정 키를 다운로드하여 config/ 폴더에 배치하세요${NC}"
    exit 1
fi

# 2. Base64 인코딩
echo -e "${BLUE}🔐 Firebase 키를 Base64로 인코딩 중...${NC}"
FIREBASE_KEY_BASE64=$(cat config/service_account_key.json | base64 | tr -d '\n')

if [ -z "$FIREBASE_KEY_BASE64" ]; then
    echo -e "${RED}❌ Base64 인코딩 실패${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Base64 인코딩 완료 (길이: ${#FIREBASE_KEY_BASE64} 문자)${NC}"

# 3. Docker 이미지 빌드
DOCKER_IMAGE="akma517/kyobodts-push-backend"
echo -e "${BLUE}🐳 Docker 이미지 빌드 중: $DOCKER_IMAGE${NC}"

docker build -t $DOCKER_IMAGE .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker 이미지 빌드 완료${NC}"
else
    echo -e "${RED}❌ Docker 이미지 빌드 실패${NC}"
    exit 1
fi

# 4. Docker Hub 푸시
echo -e "${BLUE}📤 Docker Hub에 이미지 푸시 중...${NC}"
docker push $DOCKER_IMAGE

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker Hub 푸시 완료${NC}"
else
    echo -e "${RED}❌ Docker Hub 푸시 실패${NC}"
    exit 1
fi

# 5. AWS 배포 명령어 출력
echo -e "${GREEN}🎉 배포 준비 완료!${NC}"
echo -e "${YELLOW}📋 AWS에서 실행할 명령어:${NC}"
echo ""
echo -e "${BLUE}# AWS 인스턴스에서 실행${NC}"
echo "docker pull $DOCKER_IMAGE"
echo ""
echo "docker run -d \\"
echo "  --name kyobodts-push-backend \\"
echo "  -p 5000:5000 \\"
echo "  -e FIREBASE_SERVICE_ACCOUNT_BASE64=\"$FIREBASE_KEY_BASE64\" \\"
echo "  --restart unless-stopped \\"
echo "  $DOCKER_IMAGE"
echo ""
echo -e "${YELLOW}⚠️  주의: Base64 키는 안전하게 보관하세요!${NC}"
echo -e "${GREEN}🔗 서버 확인: curl http://YOUR_AWS_IP:5000/health${NC}"