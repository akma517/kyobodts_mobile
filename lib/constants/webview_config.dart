import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewConfig {
  static InAppWebViewSettings getDefaultSettings() {
    return InAppWebViewSettings(
      iframeAllowFullscreen: true,
      iframeAllow: "camera; microphone",
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      useHybridComposition: true,
      supportMultipleWindows: true,
      allowsInlineMediaPlayback: true,
      clearCache: false,
      cacheEnabled: true,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      allowsBackForwardNavigationGestures: true,
    );
  }
}