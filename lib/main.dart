import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as foundation;

bool isAppLoading = true;
void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '교보DTS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        dialogTheme: const DialogTheme(surfaceTintColor: Colors.white),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'al_kyoboDTS_mobile'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Future<SharedPreferences> _pref = SharedPreferences.getInstance();
  late Future<List<String>> _loginInfo;
  final formKey = GlobalKey<FormState>();
  late bool isAutoLogin_GROUPWARE;
  late bool isAutoLogin_GPRO;
  bool isLoginPage = false;
  late String GROUPWARE_ID;
  late String GROUPWARE_PW;
  late String GPRO_ID;
  late String GPRO_PW;
  static const String GPRO = "GPRO";
  static const String GROUPWARE = "GROUPWARE";
  static const String AUTOLOGIN_GPRO = "AUTOLOGIN_GPRO";
  static const String AUTOLOGIN_GROUPWARE = "AUTOLOGIN_GROUPWARE";

  Future<void> _getPref(String state) async {
    final SharedPreferences pref = await _pref;
    final List<String> loginInfo =
        pref.getStringList(state) ?? ['emptyID', 'emptyPW'];
    final bool bAutoLoginState = pref.getBool(
            state == GROUPWARE ? AUTOLOGIN_GROUPWARE : AUTOLOGIN_GPRO) ??
        false;
    setState(() {
      switch (state) {
        case GROUPWARE:
          GROUPWARE_ID = loginInfo[0];
          GROUPWARE_PW = loginInfo[1];
          isAutoLogin_GROUPWARE = bAutoLoginState;
          break;
        case GPRO:
          GPRO_ID = loginInfo[0];
          GPRO_PW = loginInfo[1];
          isAutoLogin_GPRO = bAutoLoginState;
          break;
        default:
          break;
      }
    });
  }

  Future<void> _setPref(List<String> loginInfo, String state) async {
    final SharedPreferences prefs = await _pref;
    prefs.setStringList(state, loginInfo).then((success) => _getPref(state));
  }

  Future<void> _setPref_autoLogin(
      String autoLoginState, bool isAutoLogin) async {
    final SharedPreferences prefs = await _pref;
    prefs.setBool(autoLoginState, isAutoLogin);
  }

  InAppWebViewController? webViewController;
  InAppWebViewController? webViewController_temp;
  InAppWebViewSettings options = InAppWebViewSettings(
    iframeAllowFullscreen: true,
    iframeAllow: "camera; microphone",
    useShouldOverrideUrlLoading: true, // URL 로딩 제어
    mediaPlaybackRequiresUserGesture: false, // 미디어 자동 재생
    javaScriptEnabled: true, // 자바스크립트 실행 여부
    javaScriptCanOpenWindowsAutomatically: true, // 팝업 여부
    useHybridComposition: true, // 하이브리드 사용을 위한 안드로이드 웹뷰 최적화
    supportMultipleWindows: true, // 멀티 윈도우 허용
    allowsInlineMediaPlayback: true, // 웹뷰 내 미디어 재생 허용
  );

  Future<void> _setLoginInfo(String state) {
    switch (state) {
      case GROUPWARE:
        webViewController!.evaluateJavascript(
            source:
                "document.querySelector('#j_username').value = '$GROUPWARE_ID'");
        webViewController!.evaluateJavascript(
            source:
                "document.querySelector('#j_password').value = '$GROUPWARE_PW'");
        webViewController!
            .evaluateJavascript(source: "document.loginForm.submit()");
        break;
      case GPRO:
        webViewController!.evaluateJavascript(
            source:
                "document.querySelector('#email-address').value = '$GPRO_ID'");
        webViewController!.evaluateJavascript(
            source: "document.querySelector('#password').value = '$GPRO_PW'");
        webViewController!.evaluateJavascript(
            source:
                """document.querySelector("input[type='submit']").click()""");
        break;
      default:
        break;
    }

    return Future.value();
  }

  @override
  void initState() {
    super.initState();
    _loginInfo = _pref.then((SharedPreferences pref) {
      var tPref = pref.getStringList(GROUPWARE) ?? ["emptyID", "emptyPW"];
      GROUPWARE_ID = tPref[0];
      GROUPWARE_PW = tPref[1];
      tPref = pref.getStringList(GPRO) ?? ["emptyID", "emptyPW"];
      GPRO_ID = tPref[0];
      GPRO_PW = tPref[1];
      isAutoLogin_GROUPWARE = pref.getBool(AUTOLOGIN_GROUPWARE) ?? false;
      isAutoLogin_GPRO = pref.getBool(AUTOLOGIN_GPRO) ?? false;
      return tPref;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
            child: FutureBuilder<List<String>>(
                future: _loginInfo,
                builder: (BuildContext context,
                    AsyncSnapshot<List<String>> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const CircularProgressIndicator();
                    case ConnectionState.active:
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Stack(
                          children: [
                            InAppWebView(
                              initialSettings: options,
                              initialUrlRequest: URLRequest(
                                url: WebUri(
                                    'https://km.kyobodts.co.kr/common/security/login.do'),
                              ),
                              onCreateWindow:
                                  (controller, createWindowAction) async {
                                if (foundation.defaultTargetPlatform ==
                                    TargetPlatform.android) {
                                  await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (context) => StatefulBuilder(
                                      builder: (context, setState)=>Scaffold(
                                        body: SafeArea(
                                          child: Center(
                                            child: Stack(children: [
                                              InAppWebView(
                                                  // 메인 웹뷰에서 받은 windowId
                                                  initialSettings: options,
                                                  windowId:
                                                      createWindowAction.windowId,
                                                  onWebViewCreated: (controller) {
                                                    webViewController_temp =
                                                        webViewController;
                                                    webViewController =
                                                        controller;
                                                  },
                                                  // 팝업 닫기 기능 구현
                                                  onCloseWindow: (controller) {
                                                    webViewController =
                                                        webViewController_temp;
                                                    Navigator.pop(context);
                                                  },
                                                  onLoadStop: (controller, url) {
                                                    var sURL = url.toString();
                                                    if (sURL.contains(
                                                        'https://km.kyobodts.co.kr/common/security/login.do')) {
                                                      isLoginPage = true;
                                      
                                                      if (isAppLoading) {
                                                        isAppLoading = false;
                                                        FlutterNativeSplash
                                                            .remove();
                                                      }
                                      
                                                      if (isAutoLogin_GROUPWARE)
                                                        _setLoginInfo(GROUPWARE);
                                                    } else if (sURL.contains(
                                                            'https://kyobodts.wf.api.groupware.pro/v1/common/local/login') ||
                                                        sURL.contains(
                                                            'https://kyobodts.api.groupware.pro/v1/common/local/login')) {
                                                      isLoginPage = true;
                                      
                                                      if (isAutoLogin_GPRO)
                                                        _setLoginInfo(GPRO);
                                                    } else {
                                                      isLoginPage = false;
                                                    }
                                                    setState(() {});
                                                  },
                                                  onPermissionRequest:
                                                      (controller,
                                                          request) async {
                                                    return PermissionResponse(
                                                        resources:
                                                            request.resources,
                                                        action:
                                                            PermissionResponseAction
                                                                .GRANT);
                                                  },
                                                  shouldOverrideUrlLoading:
                                                      (controller,
                                                          navigationAction) async {
                                                    var uri = navigationAction
                                                        .request.url!;
                                      
                                                    if (![
                                                      "http",
                                                      "https",
                                                      "file",
                                                      "chrome",
                                                      "data",
                                                      "javascript",
                                                      "about"
                                                    ].contains(uri.scheme)) {
                                                      if (await canLaunchUrl(
                                                          uri)) {
                                                        // Launch the App
                                                        await launchUrl(
                                                          uri,
                                                        );
                                                        // and cancel the request
                                                        return NavigationActionPolicy
                                                            .CANCEL;
                                                      }
                                                    }
                                      
                                                    return NavigationActionPolicy
                                                        .ALLOW;
                                                  })
                                            ]),
                                          ),
                                        ),
                                        bottomNavigationBar: BottomNavigationBar(
                                          showSelectedLabels: false,
                                          showUnselectedLabels: false,
                                          items: <BottomNavigationBarItem>[
                                            BottomNavigationBarItem(
                                              icon: GestureDetector(
                                                child: const Icon(
                                                    Icons.arrow_back_ios),
                                                behavior:
                                                    HitTestBehavior.translucent,
                                                onTap: () {
                                                  webViewController!
                                                      .canGoBack()
                                                      .then((success) {
                                                    if (success) {
                                                      webViewController!.goBack();
                                                    } else {
                                                      Navigator.of(context,
                                                              rootNavigator: true)
                                                          .pop();
                                                    }
                                                  });
                                                },
                                              ),
                                              label: '',
                                            ),
                                            BottomNavigationBarItem(
                                              icon: GestureDetector(
                                                child: const Icon(
                                                    Icons.arrow_forward_ios),
                                                behavior:
                                                    HitTestBehavior.translucent,
                                                onTap: () {
                                                  webViewController!.goForward();
                                                },
                                              ),
                                              label: '',
                                            ),
                                            BottomNavigationBarItem(
                                              icon: GestureDetector(
                                                  child: const Icon(Icons.home,
                                                      size: 30),
                                                  behavior:
                                                      HitTestBehavior.translucent,
                                                  onTap: () {
                                                    Navigator.of(context,
                                                            rootNavigator: true)
                                                        .pop();
                                                  }),
                                              label: '',
                                            ),
                                            BottomNavigationBarItem(
                                              icon: GestureDetector(
                                                child: const Icon(Icons.info,
                                                    size: 25),
                                                behavior:
                                                    HitTestBehavior.translucent,
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return StatefulBuilder(
                                                        builder:
                                                            (context, setState) =>
                                                                AlertDialog(
                                                          scrollable: true,
                                                          content: SizedBox(
                                                            width: 200,
                                                            height: 300,
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Form(
                                                                  key: formKey,
                                                                  child: Column(
                                                                    children: [
                                                                      TextFormField(
                                                                        keyboardType:
                                                                            TextInputType
                                                                                .text,
                                                                        decoration:
                                                                            const InputDecoration(
                                                                          border:
                                                                              OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(),
                                                                          ),
                                                                          errorBorder:
                                                                              OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(),
                                                                          ),
                                                                          hintStyle:
                                                                              TextStyle(fontSize: 11),
                                                                          labelText:
                                                                              "GROUPWARE ID",
                                                                          hintText:
                                                                              "ID를 입력해 주세요",
                                                                        ),
                                                                        initialValue:
                                                                            GROUPWARE_ID,
                                                                        validator:
                                                                            (value) {
                                                                          if (value!
                                                                              .isEmpty)
                                                                            return "ID를 입력해 주세요";
                                                                        },
                                                                        onSaved:
                                                                            (newValue) =>
                                                                                {
                                                                          GROUPWARE_ID =
                                                                              newValue!
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            20,
                                                                      ),
                                                                      TextFormField(
                                                                        keyboardType:
                                                                            TextInputType
                                                                                .text,
                                                                        obscureText:
                                                                            true,
                                                                        decoration:
                                                                            const InputDecoration(
                                                                          border:
                                                                              OutlineInputBorder(),
                                                                          errorBorder:
                                                                              OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(),
                                                                          ),
                                                                          hintStyle:
                                                                              TextStyle(fontSize: 11),
                                                                          labelText:
                                                                              "GROUPWARE Password",
                                                                          hintText:
                                                                              "Password를 입력해 주세요",
                                                                        ),
                                                                        initialValue:
                                                                            GROUPWARE_PW,
                                                                        validator:
                                                                            (value) {
                                                                          if (value!
                                                                              .isEmpty) {
                                                                            return "Password를 입력해 주세요";
                                                                          }
                                                                        },
                                                                        onSaved:
                                                                            (newValue) =>
                                                                                {
                                                                          GROUPWARE_PW =
                                                                              newValue!
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            10,
                                                                      ),
                                                                      Row(
                                                                        children: [
                                                                          Checkbox(
                                                                              value:
                                                                                  isAutoLogin_GROUPWARE,
                                                                              onChanged:
                                                                                  (newValue) async {
                                                                                final SharedPreferences prefs = await _pref;
                                                                                prefs.setBool(AUTOLOGIN_GROUPWARE, newValue!).then((success) => setState(() {
                                                                                      isAutoLogin_GROUPWARE = newValue!;
                                                                                    }));
                                                                              }),
                                                                          const Text(
                                                                              "자동 로그인"),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            20,
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            50,
                                                                        width: MediaQuery.of(context)
                                                                                .size
                                                                                .width *
                                                                            0.5,
                                                                        child:
                                                                            OutlinedButton(
                                                                          onPressed:
                                                                              () {
                                                                            final formKeyState =
                                                                                formKey.currentState!;
                                                                            if (formKeyState
                                                                                .validate())
                                                                              formKeyState.save();
                                                                            _setPref([
                                                                              GROUPWARE_ID,
                                                                              GROUPWARE_PW
                                                                            ], GROUPWARE)
                                                                                .then((value) => Navigator.pop(context));
                                                                          },
                                                                          child:
                                                                              const Text(
                                                                            "저장",
                                                                            style:
                                                                                TextStyle(
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            20,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          //insetPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              label: '',
                                            ),
                                            BottomNavigationBarItem(
                                              icon: GestureDetector(
                                                child: const Icon(
                                                  Icons.g_mobiledata,
                                                  size: 40,
                                                ),
                                                behavior:
                                                    HitTestBehavior.translucent,
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return StatefulBuilder(
                                                        builder:
                                                            (context, setState) =>
                                                                AlertDialog(
                                                          scrollable: true,
                                                          content: SizedBox(
                                                            width: 200,
                                                            height: 300,
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Form(
                                                                  key: formKey,
                                                                  child: Column(
                                                                    children: [
                                                                      TextFormField(
                                                                        keyboardType:
                                                                            TextInputType
                                                                                .text,
                                                                        decoration:
                                                                            const InputDecoration(
                                                                          border:
                                                                              OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(),
                                                                          ),
                                                                          errorBorder:
                                                                              OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(),
                                                                          ),
                                                                          hintStyle:
                                                                              TextStyle(fontSize: 11),
                                                                          labelText:
                                                                              "GPRO ID",
                                                                          hintText:
                                                                              "ID를 입력해 주세요",
                                                                        ),
                                                                        initialValue:
                                                                            GPRO_ID,
                                                                        validator:
                                                                            (value) {
                                                                          if (value!
                                                                              .isEmpty)
                                                                            return "ID를 입력해 주세요";
                                                                        },
                                                                        onSaved:
                                                                            (newValue) =>
                                                                                {
                                                                          GPRO_ID =
                                                                              newValue!
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            20,
                                                                      ),
                                                                      TextFormField(
                                                                        keyboardType:
                                                                            TextInputType
                                                                                .text,
                                                                        obscureText:
                                                                            true,
                                                                        decoration:
                                                                            const InputDecoration(
                                                                          border:
                                                                              OutlineInputBorder(),
                                                                          errorBorder:
                                                                              OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(),
                                                                          ),
                                                                          hintStyle:
                                                                              TextStyle(fontSize: 11),
                                                                          labelText:
                                                                              "GPRO Password",
                                                                          hintText:
                                                                              "Password를 입력해 주세요",
                                                                        ),
                                                                        initialValue:
                                                                            GPRO_PW,
                                                                        validator:
                                                                            (value) {
                                                                          if (value!
                                                                              .isEmpty) {
                                                                            return "Password를 입력해 주세요";
                                                                          }
                                                                        },
                                                                        onSaved:
                                                                            (newValue) =>
                                                                                {
                                                                          GPRO_PW =
                                                                              newValue!
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            10,
                                                                      ),
                                                                      Row(
                                                                        children: [
                                                                          Checkbox(
                                                                              value:
                                                                                  isAutoLogin_GPRO,
                                                                              onChanged:
                                                                                  (newValue) async {
                                                                                final SharedPreferences prefs = await _pref;
                                                                                prefs.setBool(AUTOLOGIN_GPRO, newValue!).then((success) => setState(() {
                                                                                      isAutoLogin_GPRO = newValue!;
                                                                                      setState(() {});
                                                                                    }));
                                                                              }),
                                                                          const Text(
                                                                              "자동 로그인"),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            20,
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            50,
                                                                        width: MediaQuery.of(context)
                                                                                .size
                                                                                .width *
                                                                            0.5,
                                                                        child:
                                                                            OutlinedButton(
                                                                          onPressed:
                                                                              () {
                                                                            final formKeyState =
                                                                                formKey.currentState!;
                                                                            if (formKeyState
                                                                                .validate())
                                                                              formKeyState.save();
                                                                            _setPref([
                                                                              GPRO_ID,
                                                                              GPRO_PW
                                                                            ], GPRO)
                                                                                .then((value) => Navigator.pop(context));
                                                                          },
                                                                          child:
                                                                              const Text(
                                                                            "저장",
                                                                            style:
                                                                                TextStyle(
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            20,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          //insetPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              label: '',
                                            )
                                          ],
                                          selectedItemColor: Colors.black54,
                                          unselectedItemColor: Colors.black54,
                                          type: BottomNavigationBarType.fixed,
                                        ),
                                        floatingActionButton:
                                            FloatingActionButton(
                                          onPressed: () {
                                            webViewController!
                                                .getUrl()
                                                .then((url) async {
                                              var sURL = url.toString();
                                              if (sURL.contains(
                                                  'https://km.kyobodts.co.kr/common/security/login.do')) {
                                                _setLoginInfo(GROUPWARE);
                                              } else if (sURL.contains(
                                                      'https://kyobodts.wf.api.groupware.pro/v1/common/local/login') ||
                                                  sURL.contains(
                                                      'https://kyobodts.api.groupware.pro/v1/common/local/login')) {
                                                _setLoginInfo(GPRO);
                                              } else {
                                                if (kIsWeb) {
                                                  return;
                                                } else if (foundation
                                                        .defaultTargetPlatform ==
                                                    TargetPlatform.android) {
                                                  webViewController?.reload();
                                                } else if (foundation
                                                        .defaultTargetPlatform ==
                                                    TargetPlatform.iOS) {
                                                  webViewController?.loadUrl(
                                                      urlRequest: URLRequest(
                                                          url:
                                                              await webViewController!
                                                                  .getUrl()));
                                                }
                                              }
                                            });
                                          },
                                          tooltip: 'autoLogin',
                                          child: isLoginPage
                                              ? Icon(Icons.login)
                                              : Icon(Icons.refresh),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              onWebViewCreated: (controller) {
                                webViewController = controller;
                              },
                              onPermissionRequest: (controller, request) async {
                                return PermissionResponse(
                                    resources: request.resources,
                                    action: PermissionResponseAction.GRANT);
                              },
                              onLoadStop: (controller, url) {
                                var sURL = url.toString();
                                if (sURL.contains(
                                    'https://km.kyobodts.co.kr/common/security/login.do')) {
                                  isLoginPage = true;

                                  if (isAppLoading) {
                                    isAppLoading = false;
                                    FlutterNativeSplash.remove();
                                  }

                                  if (isAutoLogin_GROUPWARE)
                                    _setLoginInfo(GROUPWARE);
                                } else if (sURL.contains(
                                        'https://kyobodts.wf.api.groupware.pro/v1/common/local/login') ||
                                    sURL.contains(
                                        'https://kyobodts.api.groupware.pro/v1/common/local/login')) {
                                  isLoginPage = true;

                                  if (isAutoLogin_GPRO) _setLoginInfo(GPRO);
                                } else {
                                  isLoginPage = false;
                                }
                                setState(() {});
                              },
                              shouldOverrideUrlLoading:
                                  (controller, navigationAction) async {
                                var uri = navigationAction.request.url!;

                                if (![
                                  "http",
                                  "https",
                                  "file",
                                  "chrome",
                                  "data",
                                  "javascript",
                                  "about"
                                ].contains(uri.scheme)) {
                                  if (await canLaunchUrl(uri)) {
                                    // Launch the App
                                    await launchUrl(
                                      uri,
                                    );
                                    // and cancel the request
                                    return NavigationActionPolicy.CANCEL;
                                  }
                                }

                                return NavigationActionPolicy.ALLOW;
                              },
                            )
                          ],
                        );
                      }
                  }
                })),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          webViewController!.getUrl().then((url) async {
            var sURL = url.toString();
            if (sURL.contains(
                'https://km.kyobodts.co.kr/common/security/login.do')) {
              _setLoginInfo(GROUPWARE);
            } else if (sURL.contains(
                'https://kyobodts.wf.api.groupware.pro/v1/common/local/login')) {
              _setLoginInfo(GPRO);
            } else {
              if (kIsWeb) {
                return;
              } else if (foundation.defaultTargetPlatform ==
                  TargetPlatform.android) {
                webViewController?.reload();
              } else if (foundation.defaultTargetPlatform ==
                  TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController!.getUrl()));
              }
            }
          });
        },
        tooltip: 'autoLogin',
        child: isLoginPage ? Icon(Icons.login) : Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: GestureDetector(
              child: const Icon(Icons.arrow_back_ios),
              behavior: HitTestBehavior.translucent,
              onTap: () {
                webViewController!.goBack();
              },
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              child: const Icon(Icons.arrow_forward_ios),
              behavior: HitTestBehavior.translucent,
              onTap: () {
                webViewController!.goForward();
              },
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
                child: const Icon(Icons.home, size: 30),
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  webViewController!.getUrl().then((url) {
                    var sURL = url.toString();
                    if (!sURL.contains(
                        'https://km.kyobodts.co.kr/common/security/login.do')) {
                      webViewController!.loadUrl(
                        urlRequest: URLRequest(
                          url: WebUri(
                              'https://km.kyobodts.co.kr/common/security/loginMain.do'),
                        ),
                      );
                    }
                  });
                }),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              child: const Icon(Icons.info, size: 25),
              behavior: HitTestBehavior.translucent,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) => AlertDialog(
                        scrollable: true,
                        content: SizedBox(
                          width: 200,
                          height: 300,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Form(
                                key: formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      keyboardType: TextInputType.text,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(),
                                        ),
                                        hintStyle: TextStyle(fontSize: 11),
                                        labelText: "GROUPWARE ID",
                                        hintText: "ID를 입력해 주세요",
                                      ),
                                      initialValue: GROUPWARE_ID,
                                      validator: (value) {
                                        if (value!.isEmpty)
                                          return "ID를 입력해 주세요";
                                      },
                                      onSaved: (newValue) =>
                                          {GROUPWARE_ID = newValue!},
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    TextFormField(
                                      keyboardType: TextInputType.text,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(),
                                        ),
                                        hintStyle: TextStyle(fontSize: 11),
                                        labelText: "GROUPWARE Password",
                                        hintText: "Password를 입력해 주세요",
                                      ),
                                      initialValue: GROUPWARE_PW,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "Password를 입력해 주세요";
                                        }
                                      },
                                      onSaved: (newValue) =>
                                          {GROUPWARE_PW = newValue!},
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                            value: isAutoLogin_GROUPWARE,
                                            onChanged: (newValue) async {
                                              final SharedPreferences prefs =
                                                  await _pref;
                                              prefs
                                                  .setBool(AUTOLOGIN_GROUPWARE,
                                                      newValue!)
                                                  .then(
                                                      (success) => setState(() {
                                                            isAutoLogin_GROUPWARE =
                                                                newValue!;
                                                          }));
                                            }),
                                        const Text("자동 로그인"),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: 50,
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          final formKeyState =
                                              formKey.currentState!;
                                          if (formKeyState.validate())
                                            formKeyState.save();
                                          _setPref([GROUPWARE_ID, GROUPWARE_PW],
                                                  GROUPWARE)
                                              .then((value) =>
                                                  Navigator.pop(context));
                                        },
                                        child: const Text(
                                          "저장",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        //insetPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                      ),
                    );
                  },
                );
              },
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              child: const Icon(
                Icons.g_mobiledata,
                size: 40,
              ),
              behavior: HitTestBehavior.translucent,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) => AlertDialog(
                        scrollable: true,
                        content: SizedBox(
                          width: 200,
                          height: 300,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Form(
                                key: formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      keyboardType: TextInputType.text,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(),
                                        ),
                                        hintStyle: TextStyle(fontSize: 11),
                                        labelText: "GPRO ID",
                                        hintText: "ID를 입력해 주세요",
                                      ),
                                      initialValue: GPRO_ID,
                                      validator: (value) {
                                        if (value!.isEmpty)
                                          return "ID를 입력해 주세요";
                                      },
                                      onSaved: (newValue) =>
                                          {GPRO_ID = newValue!},
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    TextFormField(
                                      keyboardType: TextInputType.text,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(),
                                        ),
                                        hintStyle: TextStyle(fontSize: 11),
                                        labelText: "GPRO Password",
                                        hintText: "Password를 입력해 주세요",
                                      ),
                                      initialValue: GPRO_PW,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "Password를 입력해 주세요";
                                        }
                                      },
                                      onSaved: (newValue) =>
                                          {GPRO_PW = newValue!},
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                            value: isAutoLogin_GPRO,
                                            onChanged: (newValue) async {
                                              final SharedPreferences prefs =
                                                  await _pref;
                                              prefs
                                                  .setBool(
                                                      AUTOLOGIN_GPRO, newValue!)
                                                  .then(
                                                      (success) => setState(() {
                                                            isAutoLogin_GPRO =
                                                                newValue!;
                                                            setState(() {});
                                                          }));
                                            }),
                                        const Text("자동 로그인"),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: 50,
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          final formKeyState =
                                              formKey.currentState!;
                                          if (formKeyState.validate())
                                            formKeyState.save();
                                          _setPref([GPRO_ID, GPRO_PW], GPRO)
                                              .then((value) =>
                                                  Navigator.pop(context));
                                        },
                                        child: const Text(
                                          "저장",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        //insetPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                      ),
                    );
                  },
                );
              },
            ),
            label: '',
          )
        ],
        selectedItemColor: Colors.black54,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
