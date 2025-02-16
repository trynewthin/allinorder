import 'package:flutter/material.dart';
import '../utils/platform_adapter.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return PlatformAdapter.buildAppBar(context, title: title);
  }
}
