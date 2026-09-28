import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../storage/app_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.repo});

  final AppRepository repo;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int _urgentDays;
  late Set<int> _notifyDays;
  late TimeOfDay _time;
  late final TextEditingController _membruCtrl;
  late List<String> _members;

  static const _optiuniNotif = [60, 30, 14, 7, 3, 1, 0];

  @override
  void initState() {
    super.initState();
    final s = widget.repo.settings;
    _urgentDays = s.urgentDays;
    _notifyDays = s.notifyDaysBefore.toSet();
    _time = TimeOfDay(hour: s.notifyHour, minute: s.notifyMinute);
    _members = [...s.members];
    _membruCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _membruCtrl.dispose();
    super.dispose();
  }

  AppSettings _build() => AppSettings(
        urgentDays: _urgentDays,
        notifyDaysBefore: (_notifyDays.toList()..sort((a, b) => b.compareTo(a))),
        notifyHour: _time.hour,
        notifyMinute: _time.minute,
        members: _members,
      );

  Future<void> _persist() async {
    await widget.repo.updateSettings(_build());
  }

  Future<void> _alegeOra() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t == null) return;
    setState(() => _time = t);
    await _persist();
  }

  Future<void> _importa() async {
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import backup'),
        content: const Text(
          'Înlocuiești toate documentele sau le unești cu cele existente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Unește'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Înlocuiește'),
          ),
        ],
      ),
    );
    if (replace == null) return;
    final n = await widget.repo.importBackup(replace: replace);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(n == 0
            ? 'Niciun document importat.'
            : 'Importate $n documente.'),
      ),
    );
    setState(() {
      _members = [...widget.repo.settings.members];
      _urgentDays = widget.repo.settings.urgentDays;
      _notifyDays = widget.repo.settings.notifyDaysBefore.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setări')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Text('Prag urgență',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          Text(
            'Un document e urgent dacă expiră în $_urgentDays zile sau mai puțin.',
          ),
          Slider(
            min: 7,
            max: 90,
            divisions: 83,
            label: '$_urgentDays zile',
            value: _urgentDays.toDouble(),
            onChanged: (v) => setState(() => _urgentDays = v.round()),
            onChangeEnd: (_) => _persist(),
          ),
          const SizedBox(height: 12),
          const Text('Notificări',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const Text('Cu câte zile înainte vrei alerte:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _optiuniNotif.map((d) {
              final selected = _notifyDays.contains(d);
              return FilterChip(
                label: Text(d == 0 ? 'în ziua expirării' : '$d zile'),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _notifyDays.add(d);
                    } else {
                      _notifyDays.remove(d);
                    }
                  });
                  _persist();
                },
              );
            }).toList(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ora alertei'),
            subtitle: Text(_time.format(context)),
            trailing: const Icon(Icons.schedule),
            onTap: _alegeOra,
          ),
          FilledButton.tonalIcon(
            onPressed: () async {
              final ok = await NotificationService.instance.requestPermissions();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Notificările sunt activate.'
                        : 'Nu am putut activa notificările pe acest dispozitiv.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Activează notificările'),
          ),
          const SizedBox(height: 24),
          const Text('Membrii familiei',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _membruCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Adaugă membru',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _adaugaMembru(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _adaugaMembru,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _members
                .map(
                  (m) => InputChip(
                    label: Text(m),
                    onDeleted: () {
                      setState(() => _members.remove(m));
                      _persist();
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text('Backup',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.repo.exportBackup(),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Exportă JSON'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importa,
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text('Importă JSON'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _adaugaMembru() {
    final name = _membruCtrl.text.trim();
    if (name.isEmpty) return;
    if (!_members.any((m) => m.toLowerCase() == name.toLowerCase())) {
      setState(() => _members.add(name));
      _persist();
    }
    _membruCtrl.clear();
  }
}
