class LoginInfo {
  final String id;
  final String password;
  final bool isAutoLogin;

  LoginInfo({
    required this.id,
    required this.password,
    required this.isAutoLogin,
  });

  LoginInfo copyWith({
    String? id,
    String? password,
    bool? isAutoLogin,
  }) {
    return LoginInfo(
      id: id ?? this.id,
      password: password ?? this.password,
      isAutoLogin: isAutoLogin ?? this.isAutoLogin,
    );
  }

  List<String> toStringList() {
    return [id, password];
  }

  static LoginInfo fromStringList(List<String> list, bool isAutoLogin) {
    return LoginInfo(
      id: list.isNotEmpty ? list[0] : 'emptyID',
      password: list.length > 1 ? list[1] : 'emptyPW',
      isAutoLogin: isAutoLogin,
    );
  }
}