import 'package:flutter/material.dart';
import '../models/login_info.dart';
import '../services/preferences_service.dart';
import '../constants/app_constants.dart';

class LoginFormDialog extends StatefulWidget {
  final String systemType;
  final LoginInfo initialLoginInfo;
  final VoidCallback? onSaved;

  const LoginFormDialog({
    super.key,
    required this.systemType,
    required this.initialLoginInfo,
    this.onSaved,
  });

  @override
  State<LoginFormDialog> createState() => _LoginFormDialogState();
}

class _LoginFormDialogState extends State<LoginFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _preferencesService = PreferencesService();
  
  late String _id;
  late String _password;
  late bool _isAutoLogin;

  @override
  void initState() {
    super.initState();
    _id = widget.initialLoginInfo.id;
    _password = widget.initialLoginInfo.password;
    _isAutoLogin = widget.initialLoginInfo.isAutoLogin;
  }

  String get _systemLabel => widget.systemType == AppConstants.GROUPWARE ? 'GROUPWARE' : 'GPRO';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      content: SizedBox(
        width: 200,
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(),
                      ),
                      hintStyle: const TextStyle(fontSize: 11),
                      labelText: "$_systemLabel ID",
                      hintText: "ID를 입력해 주세요",
                    ),
                    initialValue: _id,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "ID를 입력해 주세요";
                      }
                      return null;
                    },
                    onSaved: (newValue) => _id = newValue!,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(),
                      ),
                      hintStyle: const TextStyle(fontSize: 11),
                      labelText: "$_systemLabel Password",
                      hintText: "Password를 입력해 주세요",
                    ),
                    initialValue: _password,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Password를 입력해 주세요";
                      }
                      return null;
                    },
                    onSaved: (newValue) => _password = newValue!,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAutoLogin,
                        onChanged: (newValue) async {
                          await _preferencesService.saveAutoLoginSetting(
                            widget.systemType, 
                            newValue!
                          );
                          setState(() {
                            _isAutoLogin = newValue;
                          });
                        }
                      ),
                      const Text("자동 로그인"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: OutlinedButton(
                      onPressed: () async {
                        final formState = _formKey.currentState!;
                        if (formState.validate()) {
                          formState.save();
                          final loginInfo = LoginInfo(
                            id: _id,
                            password: _password,
                            isAutoLogin: _isAutoLogin,
                          );
                          await _preferencesService.saveLoginInfo(
                            widget.systemType, 
                            loginInfo
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            widget.onSaved?.call();
                          }
                        }
                      },
                      child: const Text(
                        "저장",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}