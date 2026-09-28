import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../io/io_support.dart';
import '../models/app_settings.dart';
import '../models/doc.dart';
import '../services/notification_service.dart';
import '../utils/dates.dart';

class AppRepository extends ChangeNotifier {
  static const _docsKey = 'famdocs-v1';
  static const _settingsKey = 'famdocs-settings-v1';

  List<Doc> docs = [];
  AppSettings settings = AppSettings.defaults();
  bool loaded = false;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_docsKey);
    if (raw == null) {
      docs = _demo();
      await _persistDocs(p);
    } else {
      docs = (jsonDecode(raw) as List)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final sraw = p.getString(_settingsKey);
    if (sraw != null) {
      settings = AppSettings.fromJson(jsonDecode(sraw) as Map<String, dynamic>);
    }
    settings = _withMembersFromDocs(settings, docs);
    loaded = true;
    notifyListeners();
    await NotificationService.instance.syncAll(docs, settings);
  }

  Future<void> upsert(Doc doc) async {
    final i = docs.indexWhere((d) => d.id == doc.id);
    if (i >= 0) {
      docs[i] = doc;
    } else {
      docs.add(doc);
    }
    settings = _withMembersFromDocs(settings, docs);
    await _saveAll();
    await NotificationService.instance.syncDoc(doc, settings);
  }

  Future<void> remove(Doc doc) async {
    docs.removeWhere((d) => d.id == doc.id);
    await deleteLocalFile(doc.imagePath);
    await NotificationService.instance.cancelDoc(doc.id);
    await _saveAll();
  }

  Future<void> updateSettings(AppSettings next) async {
    settings = _withMembersFromDocs(next, docs);
    await _saveAll();
    await NotificationService.instance.syncAll(docs, settings);
  }

  Future<void> exportBackup() async {
    final payload = jsonEncode({
      'docs': docs.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
    });
    final path = await writeTempTextFile('docalert-backup.json', payload);
    if (path == null) {
      await SharePlus.instance.share(ShareParams(text: payload, title: 'Backup DocAlert'));
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/json')],
        title: 'Backup DocAlert',
      ),
    );
  }

  /// Returnează câte documente au fost importate.
  Future<int> importBackup({required bool replace}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return 0;
    final file = result.files.first;
    final text = file.bytes != null
        ? utf8.decode(file.bytes!)
        : (file.path != null ? await readTextFile(file.path!) : null);
    if (text == null || text.isEmpty) return 0;

    final decoded = jsonDecode(text);
    late final List list;
    AppSettings? importedSettings;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = decoded['docs'] as List? ?? const [];
      if (decoded['settings'] is Map<String, dynamic>) {
        importedSettings =
            AppSettings.fromJson(decoded['settings'] as Map<String, dynamic>);
      }
    } else {
      return 0;
    }

    final incoming = list
        .map((e) => Doc.fromJson(e as Map<String, dynamic>))
        .toList();
    if (replace) {
      docs = incoming;
    } else {
      final byId = {for (final d in docs) d.id: d};
      for (final d in incoming) {
        byId[d.id] = d;
      }
      docs = byId.values.toList();
    }
    if (importedSettings != null) {
      settings = importedSettings;
    }
    settings = _withMembersFromDocs(settings, docs);
    await _saveAll();
    await NotificationService.instance.syncAll(docs, settings);
    return incoming.length;
  }

  Future<void> _saveAll() async {
    final p = await SharedPreferences.getInstance();
    await _persistDocs(p);
    await p.setString(_settingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> _persistDocs(SharedPreferences p) async {
    await p.setString(
      _docsKey,
      jsonEncode(docs.map((e) => e.toJson()).toList()),
    );
  }

  AppSettings _withMembersFromDocs(AppSettings s, List<Doc> list) {
    final names = {...s.members, ...list.map((d) => d.membru)}
        .where((e) => e.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return s.copyWith(members: names);
  }

  List<Doc> _demo() => [
        Doc(
          id: 'demo-1',
          membru: 'Maria',
          nume: 'Buletin de identitate',
          categorie: 'Identitate',
          expira: dPlus(420),
        ),
        Doc(
          id: 'demo-2',
          membru: 'Andrei',
          nume: 'Asigurare RCA',
          categorie: 'Mașină',
          expira: dPlus(140),
        ),
        Doc(
          id: 'demo-3',
          membru: 'Andrei',
          nume: 'Revizie tehnică ITP',
          categorie: 'Mașină',
          expira: dPlus(20),
        ),
        Doc(
          id: 'demo-4',
          membru: 'Elena',
          nume: 'Card de sănătate',
          categorie: 'Sănătate',
          expira: dPlus(11),
        ),
        Doc(
          id: 'demo-5',
          membru: 'Mihai',
          nume: 'Permis de conducere',
          categorie: 'Identitate',
          expira: dPlus(-5),
        ),
      ];
}
