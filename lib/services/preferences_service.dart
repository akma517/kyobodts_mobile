import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_info.dart';
import '../constants/app_constants.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<LoginInfo> getLoginInfo(String systemType) async {
    final prefs = await _prefs;
    final loginData = prefs.getStringList(systemType) ?? AppConstants.DEFAULT_LOGIN_INFO;
    final autoLoginKey = systemType == AppConstants.GROUPWARE 
        ? AppConstants.AUTOLOGIN_GROUPWARE 
        : AppConstants.AUTOLOGIN_GPRO;
    final isAutoLogin = prefs.getBool(autoLoginKey) ?? false;
    
    return LoginInfo.fromStringList(loginData, isAutoLogin);
  }

  Future<void> saveLoginInfo(String systemType, LoginInfo loginInfo) async {
    final prefs = await _prefs;
    await prefs.setStringList(systemType, loginInfo.toStringList());
  }

  Future<void> saveAutoLoginSetting(String systemType, bool isAutoLogin) async {
    final prefs = await _prefs;
    final autoLoginKey = systemType == AppConstants.GROUPWARE 
        ? AppConstants.AUTOLOGIN_GROUPWARE 
        : AppConstants.AUTOLOGIN_GPRO;
    await prefs.setBool(autoLoginKey, isAutoLogin);
  }
}