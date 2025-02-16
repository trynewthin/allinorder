import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class PlatformAdapter {
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get isWeb => kIsWeb;

  static Future<void> initializePlatform() async {
    if (isDesktop) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1280, 720),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  static Future<void> minimizeWindow() async {
    if (isDesktop) {
      await windowManager.minimize();
    }
  }

  static Future<void> maximizeWindow() async {
    if (isDesktop) {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    }
  }

  static Future<void> closeWindow() async {
    if (isDesktop) {
      await windowManager.close();
    }
  }

  static Future<void> startWindowDrag() async {
    if (isDesktop) {
      await windowManager.startDragging();
    }
  }

  static String joinPaths(List<String> parts) {
    if (kIsWeb) {
      return parts.join('/');
    } else {
      return parts.join(Platform.pathSeparator);
    }
  }

  static PreferredSizeWidget buildAppBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
  }) {
    if (isDesktop) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: GestureDetector(
          onPanStart: (_) => startWindowDrag(),
          child: AppBar(
            title: Text(title),
            actions: [
              ...?actions,
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: minimizeWindow,
              ),
              IconButton(
                icon: const Icon(Icons.crop_square),
                onPressed: maximizeWindow,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: closeWindow,
              ),
            ],
          ),
        ),
      );
    } else {
      return AppBar(
        title: Text(title),
        actions: actions,
      );
    }
  }
}
