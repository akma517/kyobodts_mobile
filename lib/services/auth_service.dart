import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<bool> login(String id, String password, bool autoLogin) async {
    try {
      print('AuthService.login: START - id: $id, autoLogin: $autoLogin');
      
      // test 계정은 mock 로그인
      if (id == 'test') {
        print('AuthService.login: Test account login attempt');
        if (password == '1234') {
          _currentUser = User(
            id: 'test',
            name: '홍길동',
            email: 'test@kyobodts.com',
          );
          
          if (autoLogin) {
            await _saveLoginInfo(id, password);
          }
          
          print('AuthService.login: Test account login SUCCESS');
          return true;
        }
        print('AuthService.login: Test account login FAILED - wrong password');
        return false;
      }
      
      // 실제 계정은 API 호출
      print('AuthService.login: Real account login attempt');
      return await _loginWithAPI(id, password, autoLogin);
    } catch (e) {
      print('AuthService.login: Exception - $e');
      return false;
    }
  }
  
  Future<bool> _loginWithAPI(String id, String password, bool autoLogin) async {
    try {
      print('AuthService._loginWithAPI: START - Calling ${AppConstants.LOGIN_API_URL}');
      print('AuthService._loginWithAPI: Request body: j_username=$id&j_password=$password');
      
      final response = await ApiService.httpClient.post(
        Uri.parse(AppConstants.LOGIN_API_URL),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
        },
        body: 'j_username=$id&j_password=$password',
      ).timeout(const Duration(seconds: 10));
      
      // 쿠키 저장
      ApiService.saveCookies(response.headers);
      
      print('AuthService._loginWithAPI: Response status: ${response.statusCode}');
      print('AuthService._loginWithAPI: Response headers: ${response.headers}');
      print('AuthService._loginWithAPI: Response body length: ${response.body.length}');
      
      // 응답 본문 미리보기
      final bodyPreview = response.body.length > 500 ? response.body.substring(0, 500) : response.body;
      print('AuthService._loginWithAPI: Response body preview: $bodyPreview');
      
      // 로그인 성공 판단
      if (response.statusCode == 200 || response.statusCode == 302) {
        print('AuthService._loginWithAPI: HTTP status OK, checking response content');
        
        final hasError = response.body.contains('error') || response.body.contains('fail');
        print('AuthService._loginWithAPI: Contains error/fail: $hasError');
        
        if (!hasError) {
          _currentUser = User(
            id: id,
            name: id,
            email: '$id@kyobodts.com',
          );
          
          if (autoLogin) {
            print('AuthService._loginWithAPI: Saving login info for auto login');
            await _saveLoginInfo(id, password);
          }
          
          print('AuthService._loginWithAPI: Login SUCCESS - User created: ${_currentUser?.id}');
          return true;
        } else {
          print('AuthService._loginWithAPI: Login FAILED - Response contains error/fail');
        }
      } else {
        print('AuthService._loginWithAPI: Login FAILED - HTTP status: ${response.statusCode}');
      }
      
      return false;
    } catch (e) {
      print('AuthService._loginWithAPI: Exception - $e');
      return false;
    }
  }

  Future<bool> autoLogin() async {
    try {
      print('AuthService.autoLogin: START');
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('login_id');
      final password = prefs.getString('login_password');
      
      print('AuthService.autoLogin: Stored credentials - id: $id, password: ${password != null ? "[HIDDEN]" : "null"}');
      
      if (id != null && password != null) {
        print('AuthService.autoLogin: Attempting login with stored credentials');
        return await login(id, password, false);
      }
      
      print('AuthService.autoLogin: No stored credentials found');
      return false;
    } catch (e) {
      print('AuthService.autoLogin: Error - $e');
      return false;
    }
  }

  Future<void> _saveLoginInfo(String id, String password) async {
    try {
      print('AuthService._saveLoginInfo: Saving login info for auto login');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('login_id', id);
      await prefs.setString('login_password', password);
      print('AuthService._saveLoginInfo: Login info saved successfully');
    } catch (e) {
      print('AuthService._saveLoginInfo: Error saving login info - $e');
    }
  }

  Future<void> logout() async {
    try {
      // test 계정이 아닌 경우 로그아웃 API 호출
      if (_currentUser?.id != 'test') {
        await _logoutWithAPI();
      }
    } catch (e) {
      print('AuthService.logout: API error: $e');
    } finally {
      // 에러 발생 여부와 관계없이 로컬 데이터 정리
      _currentUser = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('login_id');
        await prefs.remove('login_password');
      } catch (e) {
        print('AuthService.logout: SharedPreferences error: $e');
      }
    }
  }
  
  Future<void> _logoutWithAPI() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.LOGOUT_API_URL),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('Logout API response: ${response.statusCode}');
      // 로그아웃은 응답 결과와 관계없이 성공으로 처리
    } catch (e) {
      print('Logout API error: $e');
      // 로그아웃은 에러가 발생해도 성공으로 처리
    }
  }

  // 현재 사용자가 test 계정인지 확인
  bool get isTestAccount => _currentUser?.id == 'test';
  
  // 자동로그인 설정 확인
  Future<bool> get hasAutoLoginCredentials async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('login_id');
      final password = prefs.getString('login_password');
      return id != null && password != null;
    } catch (e) {
      return false;
    }
  }
  
  // 재로그인 시도
  Future<bool> reLogin() async {
    try {
      print('AuthService.reLogin: Attempting re-login');
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('login_id');
      final password = prefs.getString('login_password');
      
      if (id != null && password != null) {
        print('AuthService.reLogin: Re-login with stored credentials');
        return await _loginWithAPI(id, password, false);
      }
      
      print('AuthService.reLogin: No stored credentials for re-login');
      return false;
    } catch (e) {
      print('AuthService.reLogin: Error - $e');
      return false;
    }
  }
}