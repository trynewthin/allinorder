import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'models/settings_model.dart';
import 'pages/projects_page.dart';
import 'utils/platform_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlatformAdapter.initializePlatform();

  final settings = await Settings.load();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final Settings settings;

  const MyApp({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: settings,
      child: Consumer<Settings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'All In Order',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: settings.themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(settings.locale),
            home: const ProjectsPage(),
          );
        },
      ),
    );
  }
}
