import 'package:flutter/material.dart';

import '../shared/navigation/app_shell.dart';
import 'bootstrap.dart';
import 'theme/app_theme.dart';

class StokEasyApp extends StatelessWidget {
  const StokEasyApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StokEasy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AppShell(dependencies: dependencies),
    );
  }
}
