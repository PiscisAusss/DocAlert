import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../io/io_support.dart';
import '../models/doc.dart';
import '../storage/app_repository.dart';
import '../utils/dates.dart';
import '../widgets/local_image.dart';

class DocFormPage extends StatefulWidget {
  const DocFormPage({super.key, required this.repo, this.existing});

  final AppRepository repo;
  final Doc? existing;

  @override
  State<DocFormPage> createState() => _DocFormPageState();
}

class _DocFormPageState extends State<DocFormPage> {
  late final TextEditingController _membruCtrl;
  late final TextEditingController _documentCtrl;
  late final TextEditingController _noteCtrl;
  late String _categorie;
  DateTime? _dataAleasa;
  String? _imagePath;
  bool _busy = false;

  bool get _edit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _membruCtrl = TextEditingController(text: e?.membru ?? '');
    _documentCtrl = TextEditingController(text: e?.nume ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _categorie = e?.categorie ?? kCategorii.first;
    _dataAleasa = e != null ? tryParseIsoDate(e.expira) : null;
    _imagePath = e?.imagePath;
  }

  @override
  void dispose() {
    _membruCtrl.dispose();
    _documentCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _alegeData() async {
    final acum = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dataAleasa ?? acum,
      firstDate: DateTime(acum.year - 5),
      lastDate: DateTime(acum.year + 30),
    );
    if (d != null) setState(() => _dataAleasa = d);
  }

  Future<void> _alegeFoto() async {
    final picker = ImagePicker();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
ListTile(
  leading: const Icon(Icons.photo_library_outlined),
  title: const Text('Galerie'),
  onTap: () => Navigator.pop(ctx, 'gallery'),
),
ListTile(
  leading: const Icon(Icons.photo_camera_outlined),
  title: const Text('Cameră'),
  onTap: () => Navigator.pop(ctx, 'camera'),
),
if (_imagePath != null)
  ListTile(
    leading: const Icon(Icons.delete_outline),
    title: const Text('Scoate poza'),
    onTap: () => Navigator.pop(ctx, 'remove'),
  ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'remove') {
      setState(() => _imagePath = null);
      return;
    }
    final source =
        action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final id = widget.existing?.id ?? newDocId();
    final saved = await copyToAppImages(file.path, id);
    setState(() => _imagePath = saved ?? file.path);
  }

  Future<void> _salveaza() async {
    if (_membruCtrl.text.trim().isEmpty ||
        _documentCtrl.text.trim().isEmpty ||
        _dataAleasa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completează toate câmpurile obligatorii.')),
      );
      return;
    }
    setState(() => _busy = true);
    final id = widget.existing?.id ?? newDocId();
    if (widget.existing?.imagePath != null &&
        widget.existing!.imagePath != _imagePath) {
      await deleteLocalFile(widget.existing!.imagePath);
    }
    final doc = Doc(
      id: id,
      membru: _membruCtrl.text.trim(),
      nume: _documentCtrl.text.trim(),
      categorie: _categorie,
      expira: toIsoDate(_dataAleasa!),
      note: _noteCtrl.text.trim(),
      imagePath: _imagePath,
    );
    await widget.repo.upsert(doc);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _reinnoieste() async {
    if (_dataAleasa == null) return;
    final luni = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Reînnoiește cu')),
            ListTile(
              title: const Text('6 luni'),
              onTap: () => Navigator.pop(ctx, 6),
            ),
            ListTile(
              title: const Text('1 an'),
              onTap: () => Navigator.pop(ctx, 12),
            ),
            ListTile(
              title: const Text('2 ani'),
              onTap: () => Navigator.pop(ctx, 24),
            ),
          ],
        ),
      ),
    );
    if (luni == null) return;
    setState(() {
      final base = _dataAleasa!;
      final raw = DateTime(base.year, base.month + luni, 1);
      final lastDay = DateTime(raw.year, raw.month + 1, 0).day;
      final day = base.day > lastDay ? lastDay : base.day;
      _dataAleasa = DateTime(raw.year, raw.month, day);
    });
  }

  Future<void> _sterge() async {
    final d = widget.existing;
    if (d == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ștergi documentul?'),
        content: Text('"${d.nume}" al lui ${d.membru}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.repo.remove(d);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.repo.settings.members;
    return Scaffold(
      appBar: AppBar(
        title: Text(_edit ? 'Editează document' : 'Adaugă document'),
        actions: [
          if (_edit)
            IconButton(
              tooltip: 'Șterge',
              onPressed: _sterge,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _membruCtrl,
            decoration: InputDecoration(
              labelText: 'Membru familie',
              hintText: 'ex: Maria',
              border: const OutlineInputBorder(),
              suffixIcon: members.isEmpty
                  ? null
                  : PopupMenuButton<String>(
                      tooltip: 'Alege membru',
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (v) =>
                          setState(() => _membruCtrl.text = v),
                      itemBuilder: (_) => members
                          .map((m) => PopupMenuItem(value: m, child: Text(m)))
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _documentCtrl,
            decoration: const InputDecoration(
              labelText: 'Document',
              hintText: 'ex: Buletin de identitate',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: kCategorii.contains(_categorie)
                ? _categorie
                : kCategorii.last,
            decoration: const InputDecoration(
              labelText: 'Categorie',
              border: OutlineInputBorder(),
            ),
            items: kCategorii
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _categorie = v ?? _categorie),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _alegeData,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Expiră la',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _dataAleasa == null ? 'Alege data' : fmtData(toIsoDate(_dataAleasa!)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notă (opțional)',
              hintText: 'ex: dosar la notar, serie, etc.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_imagePath != null) localImageThumb(_imagePath!, size: 72),
              if (_imagePath != null) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _alegeFoto,
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(_imagePath == null ? 'Adaugă poză' : 'Schimbă poza'),
                ),
              ),
            ],
          ),
          if (_edit) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reinnoieste,
              icon: const Icon(Icons.autorenew),
              label: const Text('Reînnoiește perioada'),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _salveaza,
            child: Text(_edit ? 'Salvează' : 'Adaugă document'),
          ),
        ],
      ),
    );
  }
}
