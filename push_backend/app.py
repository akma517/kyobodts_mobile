from flask import Flask, request, jsonify
from datetime import datetime
import logging
import os
from services.firebase_service import FirebasePushService
from models.push_request import PushRequest, PushResponse

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Firebase 서비스 초기화
firebase_service = FirebasePushService()

@app.route('/health', methods=['GET'])
def health_check():
    """헬스체크 엔드포인트"""
    firebase_status = 'connected' if firebase_service.is_initialized() else 'disconnected'
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'kyobodts-push-server',
        'firebase': firebase_status
    })

@app.route('/push/send', methods=['POST'])
def send_push():
    """푸시 메시지 발송 엔드포인트"""
    try:
        # 요청 데이터 검증
        data = request.get_json()
        if not data:
            return jsonify(PushResponse.create_error("요청 데이터가 없습니다").__dict__), 400
        
        # PushRequest 객체 생성 및 검증
        push_request = PushRequest.from_dict(data)
        validation_error = push_request.validate()
        if validation_error:
            return jsonify(PushResponse.create_error(validation_error).__dict__), 400
        
        # Firebase 푸시 발송
        result = firebase_service.send_push(push_request)
        
        if result['success']:
            logger.info(f"푸시 발송 성공: {push_request.target_type}={push_request.target_value}")
            return jsonify(PushResponse.create_success(
                message="푸시 메시지가 성공적으로 발송되었습니다",
                firebase_response=result['response']
            ).__dict__)
        else:
            logger.error(f"푸시 발송 실패: {result['error']}")
            return jsonify(PushResponse.create_error(
                f"푸시 발송 실패: {result['error']}"
            ).__dict__), 500
            
    except Exception as e:
        logger.error(f"푸시 발송 중 오류 발생: {str(e)}")
        return jsonify(PushResponse.create_error(
            f"서버 오류: {str(e)}"
        ).__dict__), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'success': False,
        'error': 'API 엔드포인트를 찾을 수 없습니다',
        'available_endpoints': ['/health', '/push/send']
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'success': False,
        'error': '내부 서버 오류가 발생했습니다'
    }), 500

if __name__ == '__main__':
    # 프로덕션 환경에서는 debug=False
    debug_mode = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=5000, debug=debug_mode)