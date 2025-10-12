class AppConstants {
  // 시스템 타입
  static const String GPRO = "GPRO";
  static const String GROUPWARE = "GROUPWARE";
  static const String AUTOLOGIN_GPRO = "AUTOLOGIN_GPRO";
  static const String AUTOLOGIN_GROUPWARE = "AUTOLOGIN_GROUPWARE";

  // URL
  static const String GROUPWARE_LOGIN_URL = 'https://km.kyobodts.co.kr/common/security/login.do';
  static const String GROUPWARE_MAIN_URL = 'https://km.kyobodts.co.kr/common/security/loginMain.do';
  static const String LOGIN_API_URL = 'https://km.kyobodts.co.kr/j_spring_security_check';
  static const String LOGOUT_API_URL = 'https://km.kyobodts.co.kr/common/security/logout';
  static const String GPRO_LOGIN_URL1 = 'https://kyobodts.wf.api.groupware.pro/v1/common/local/login';
  static const String GPRO_LOGIN_URL2 = 'https://kyobodts.api.groupware.pro/v1/common/local/login';

  // 기본값
  static const List<String> DEFAULT_LOGIN_INFO = ['emptyID', 'emptyPW'];
  
  // 허용된 URL 스킴
  static const List<String> ALLOWED_URL_SCHEMES = [
    "http",
    "https", 
    "file",
    "chrome",
    "data",
    "javascript",
    "about"
  ];
}