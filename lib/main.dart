import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/home_screen.dart';
import 'services/firebase_service.dart';
import 'widgets/content_modal.dart';
import 'models/push_message.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  void _initializeFirebase() async {
    try {
      await FirebaseService().initialize();
      _setupPushHandling();
    } catch (e) {
      print('Firebase 초기화 실패: $e');
    }
  }

  void _setupPushHandling() {
    try {
      FirebaseService().onMessageReceived = (data) {
        final message = PushMessage.fromMap(data);
        if (message.hasContent) {
          _showContentModal(message);
        }
      };
    } catch (e) {
      print('Firebase 푸시 핸들링 설정 실패: $e');
    }
  }

  void _showContentModal(PushMessage message) {
    final context = _navigatorKey.currentContext;
    if (context != null) {
      ContentType contentType;
      switch (message.contentTypeEnum) {
        case 'pdf':
          contentType = ContentType.pdf;
          break;
        case 'asset':
          contentType = ContentType.asset;
          break;
        default:
          contentType = ContentType.html;
      }

      ContentModalHelper.showContentModal(
        context,
        contentUrl: message.contentUrl!,
        title: message.title,
        contentType: contentType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: '교보DTS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
     );
  }
}
