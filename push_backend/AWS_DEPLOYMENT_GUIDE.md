# 🚀 AWS 배포 가이드 - 보안 강화 버전

## 🎯 개요
Firebase 서비스 계정 키를 환경변수로 전달하여 보안을 강화한 배포 방식

---

## 📋 사전 준비사항

### 1. 로컬 환경
- ✅ Docker 설치
- ✅ Docker Hub 계정
- ✅ Firebase 서비스 계정 키 (`config/service_account_key.json`)

### 2. AWS 환경
- ✅ EC2 인스턴스 (Ubuntu 20.04 LTS 권장)
- ✅ Docker 설치
- ✅ Docker Compose 설치 (방법 3 사용 시)
- ✅ 포트 5000 오픈 (보안 그룹 설정)
- ✅ curl 설치 (테스트용)

---

## 🔧 배포 단계

### **Step 1: 로컬에서 이미지 빌드 및 푸시**

```bash
# 1. 배포 스크립트 실행
./deploy.sh

# 2. Docker Hub 사용자명 확인 (스크립트 내)
# DOCKER_IMAGE="akma517/kyobodts-push-backend"
```

### **Step 2: AWS EC2에서 환경변수 설정**

#### **방법 1: .env 파일 사용 (권장)**
```bash
# 1. .env 파일 생성
echo "FIREBASE_SERVICE_ACCOUNT_BASE64=YOUR_BASE64_KEY_HERE" > .env
chmod 600 .env  # 파일 권한 제한

# 2. Docker 이미지 다운로드
docker pull akma517/kyobodts-push-backend

# 3. 컨테이너 실행 (.env 파일 사용)
docker run -d \
  --name kyobodts-push-backend \
  -p 5000:5000 \
  --env-file .env \
  --restart unless-stopped \
  akma517/kyobodts-push-backend
```

#### **방법 2: 시스템 환경변수 사용**
```bash
# 1. 시스템 환경변수 설정
export FIREBASE_SERVICE_ACCOUNT_BASE64="YOUR_BASE64_KEY_HERE"
echo 'export FIREBASE_SERVICE_ACCOUNT_BASE64="YOUR_BASE64_KEY_HERE"' >> ~/.bashrc

# 2. 컨테이너 실행
docker run -d \
  --name kyobodts-push-backend \
  -p 5000:5000 \
  -e FIREBASE_SERVICE_ACCOUNT_BASE64 \
  --restart unless-stopped \
  akma517/kyobodts-push-backend
```

#### **방법 3: Docker Compose 사용 (가장 편리)**
```bash
# 1. docker-compose.yml 생성
cat > docker-compose.yml << EOF
version: '3.8'
services:
  push-backend:
    image: akma517/kyobodts-push-backend
    container_name: kyobodts-push-backend
    ports:
      - "5000:5000"
    environment:
      - FIREBASE_SERVICE_ACCOUNT_BASE64=\${FIREBASE_SERVICE_ACCOUNT_BASE64}
    restart: unless-stopped
EOF

# 2. .env 파일 생성
echo "FIREBASE_SERVICE_ACCOUNT_BASE64=YOUR_BASE64_KEY_HERE" > .env

# 3. 실행
docker-compose up -d
```

#### **상태 확인**
```bash
docker ps
curl http://localhost:5000/health
```

---

## 🔐 보안 장점

### ✅ **해결된 보안 문제**
- Firebase 서비스 계정 키가 Docker 이미지에 포함되지 않음
- Docker Hub에 민감한 정보 노출 방지
- 환경별로 다른 키 사용 가능

### ✅ **추가 보안 조치**
- `.dockerignore`로 민감한 파일 제외
- Base64 인코딩으로 키 난독화
- 환경변수를 통한 런타임 주입

---

## 🔧 문제 해결

### **Firebase 초기화 실패**
```bash
# 컨테이너 로그 확인
docker logs kyobodts-push-backend

# Base64 키 검증
echo "YOUR_BASE64_KEY" | base64 -d | jq .
```

### **포트 접근 불가**
```bash
# AWS 보안 그룹에서 5000 포트 오픈 확인
# 방화벽 설정 확인
sudo ufw status
```

### **컨테이너 재시작**
```bash
# 컨테이너 중지 및 제거
docker stop kyobodts-push-backend
docker rm kyobodts-push-backend

# 새로운 환경변수로 재실행
docker run -d \
  --name kyobodts-push-backend \
  -p 5000:5000 \
  -e FIREBASE_SERVICE_ACCOUNT_BASE64="NEW_BASE64_KEY" \
  --restart unless-stopped \
  akma517/kyobodts-push-backend
```

---

## 📊 배포 검증

### **1. 서버 상태 확인**
```bash
curl http://YOUR_AWS_IP:5000/health
# 응답: {"status": "healthy", "firebase": "connected"}
```

### **2. 푸시 테스트**
```bash
curl -X POST http://YOUR_AWS_IP:5000/push/send \
  -H "Content-Type: application/json" \
  -d '{
    "title": "배포 테스트",
    "body": "AWS 배포 성공!",
    "target_type": "topic",
    "target_value": "all_users"
  }'
```

---

## ⚡ 빠른 배포 명령어

### **로컬에서**
```bash
./deploy.sh && echo "✅ 배포 스크립트 완료"
```

### **AWS에서 (.env 파일 방식)**
```bash
# 환경변수 파일 생성
echo "FIREBASE_SERVICE_ACCOUNT_BASE64=YOUR_BASE64_KEY_HERE" > .env && \
chmod 600 .env && \
# 컨테이너 실행
docker pull akma517/kyobodts-push-backend && \
docker run -d \
  --name kyobodts-push-backend \
  -p 5000:5000 \
  --env-file .env \
  --restart unless-stopped \
  akma517/kyobodts-push-backend && \
curl http://localhost:5000/health
```

---

## 🎯 다음 단계

1. **모니터링 설정**: CloudWatch 또는 로그 수집 도구 연동
2. **HTTPS 적용**: Nginx + Let's Encrypt 설정
3. **로드 밸런싱**: 다중 인스턴스 운영 시 ALB 설정
4. **자동 배포**: GitHub Actions + AWS CodeDeploy 연동

---

**🔐 보안 강화 완료! 이제 안전하게 배포할 수 있습니다.**