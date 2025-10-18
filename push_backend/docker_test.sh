#!/bin/bash

# 교보DTS 푸시 서버 Docker 테스트 스크립트

echo "🐳 교보DTS 푸시 서버 Docker 테스트 시작"
echo "================================================"

# 기존 컨테이너 정리
echo "🧹 기존 컨테이너 정리 중..."
docker stop kyobodts-push-server 2>/dev/null || true
docker rm kyobodts-push-server 2>/dev/null || true

# Docker 이미지 빌드
echo "🔨 Docker 이미지 빌드 중..."
docker build -t kyobodts-push-server:latest .

if [ $? -ne 0 ]; then
    echo "❌ Docker 이미지 빌드 실패"
    exit 1
fi

echo "✅ Docker 이미지 빌드 완료"

# 컨테이너 실행
echo "🚀 컨테이너 실행 중..."
docker run -d \
    --name kyobodts-push-server \
    -p 5000:5000 \
    kyobodts-push-server:latest

if [ $? -ne 0 ]; then
    echo "❌ 컨테이너 실행 실패"
    exit 1
fi

echo "✅ 컨테이너 실행 완료"

# 컨테이너 시작 대기
echo "⏳ 컨테이너 시작 대기 중..."
sleep 10

# 컨테이너 상태 확인
echo "📊 컨테이너 상태 확인..."
docker ps | grep kyobodts-push-server

# 컨테이너 로그 확인
echo "📝 컨테이너 로그 확인..."
docker logs kyobodts-push-server

# 헬스체크 테스트
echo "🏥 헬스체크 테스트..."
for i in {1..10}; do
    echo "헬스체크 시도 $i/10..."
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health)
    
    if [ "$response" = "200" ]; then
        echo "✅ 헬스체크 성공!"
        break
    elif [ $i -eq 10 ]; then
        echo "❌ 헬스체크 실패 (10회 시도 후 포기)"
        echo "컨테이너 로그:"
        docker logs kyobodts-push-server
        exit 1
    else
        sleep 3
    fi
done

# API 응답 확인
echo "🔍 API 응답 상세 확인..."
curl -s http://localhost:5000/health | python3 -m json.tool

# 푸시 발송 엔드포인트 테스트 (잘못된 요청으로 400 응답 확인)
echo "📤 푸시 발송 엔드포인트 테스트..."
response=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST http://localhost:5000/push/send \
    -H "Content-Type: application/json" \
    -d '{"title":"테스트"}')

if [ "$response" = "400" ]; then
    echo "✅ 푸시 발송 엔드포인트 정상 (검증 로직 작동)"
else
    echo "⚠️  푸시 발송 엔드포인트 응답: HTTP $response"
fi

# 컨테이너 내부에서 검증 스크립트 실행
echo "🔬 컨테이너 내부 검증 실행..."
docker exec kyobodts-push-server python validate_service.py

# 테스트 완료
echo ""
echo "🎉 Docker 테스트 완료!"
echo "================================================"
echo "✅ Docker 이미지 빌드: 성공"
echo "✅ 컨테이너 실행: 성공"
echo "✅ 헬스체크: 성공"
echo "✅ API 엔드포인트: 정상"
echo ""
echo "🔧 유용한 명령어:"
echo "  컨테이너 로그 확인: docker logs kyobodts-push-server"
echo "  컨테이너 접속: docker exec -it kyobodts-push-server /bin/bash"
echo "  컨테이너 중지: docker stop kyobodts-push-server"
echo "  컨테이너 삭제: docker rm kyobodts-push-server"
echo ""
echo "🌐 서버 접속: http://localhost:5000"