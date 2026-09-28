import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_page.dart';
import 'storage/app_repository.dart';

class DocApp extends StatefulWidget {
  const DocApp({super.key, this.repository});

  /// Injecție pentru teste; în producție se creează intern.
  final AppRepository? repository;

  @override
  State<DocApp> createState() => _DocAppState();
}

class _DocAppState extends State<DocApp> {
  late final AppRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? AppRepository();
    _repo.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocAlert',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ro'),
      supportedLocales: const [Locale('ro'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E9E50),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E9E50),
          brightness: Brightness.dark,
        ),
      ),
      home: HomePage(repo: _repo),
    );
  }
}
