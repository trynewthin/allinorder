import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/custom_app_bar.dart';
import '../models/settings_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<Settings>(context);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.settings),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.theme),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.systemTheme),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.lightTheme),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.darkTheme),
                ),
              ],
              onChanged: (ThemeMode? newThemeMode) {
                if (newThemeMode != null) {
                  settings.setThemeMode(newThemeMode);
                }
              },
            ),
          ),
          ListTile(
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: settings.locale,
              items: [
                DropdownMenuItem(
                  value: 'zh',
                  child: Text(l10n.chinese),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.english),
                ),
              ],
              onChanged: (String? newLocale) {
                if (newLocale != null) {
                  settings.setLocale(newLocale);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
