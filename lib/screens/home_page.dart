import 'package:flutter/material.dart';

import '../models/doc.dart';
import '../models/doc_status.dart';
import '../storage/app_repository.dart';
import '../widgets/doc_card.dart';
import 'doc_form_page.dart';
import 'settings_page.dart';

enum _StatusFilter { all, urgent, expired, ok }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repo});

  final AppRepository repo;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _search = '';
  bool _showSearch = false;
  String? _member;
  String? _category;
  _StatusFilter _status = _StatusFilter.all;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Doc> _filtered() {
    final repo = widget.repo;
    var list = [...repo.docs];
    list.sort((a, b) => a.expira.compareTo(b.expira));
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list
          .where((d) =>
              d.nume.toLowerCase().contains(q) ||
              d.membru.toLowerCase().contains(q) ||
              d.categorie.toLowerCase().contains(q) ||
              d.note.toLowerCase().contains(q))
          .toList();
    }
    if (_member != null) {
      list = list.where((d) => d.membru == _member).toList();
    }
    if (_category != null) {
      list = list.where((d) => d.categorie == _category).toList();
    }
    if (_status != _StatusFilter.all) {
      list = list.where((d) {
        final s = statusFor(d, repo.settings);
        return switch (_status) {
          _StatusFilter.urgent => s == DocStatus.urgent,
          _StatusFilter.expired => s == DocStatus.expired,
          _StatusFilter.ok => s == DocStatus.ok,
          _StatusFilter.all => true,
        };
      }).toList();
    }
    return list;
  }

  Future<void> _confirmDelete(Doc d) async {
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
    if (ok == true) await widget.repo.remove(d);
  }

  void _openForm({Doc? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocFormPage(repo: widget.repo, existing: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final docs = widget.repo.docs;
        final settings = widget.repo.settings;
        final filtered = _filtered();
        final urgent = docs
            .where((d) => statusFor(d, settings) != DocStatus.ok)
            .length;
        final members = settings.members;
        final categories = {
          ...docs.map((d) => d.categorie),
        }.toList()
          ..sort();

        return Scaffold(
          appBar: AppBar(
            title: _showSearch
                ? TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Caută document, membru…',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  )
                : const Text('Documente familie'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(20),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${docs.length} documente · $urgent necesită atenție',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Caută',
                icon: Icon(_showSearch ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _search = '';
                      _searchCtrl.clear();
                    }
                  });
                },
              ),
              IconButton(
                tooltip: 'Setări',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(repo: widget.repo),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Adaugă'),
          ),
          body: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    _chip(
                      label: 'Toate',
                      selected: _status == _StatusFilter.all &&
                          _member == null &&
                          _category == null,
                      onTap: () => setState(() {
                        _status = _StatusFilter.all;
                        _member = null;
                        _category = null;
                      }),
                    ),
                    _chip(
                      label: 'Urgente',
                      selected: _status == _StatusFilter.urgent,
                      onTap: () => setState(() {
                        _status = _status == _StatusFilter.urgent
                            ? _StatusFilter.all
                            : _StatusFilter.urgent;
                      }),
                    ),
                    _chip(
                      label: 'Expirate',
                      selected: _status == _StatusFilter.expired,
                      onTap: () => setState(() {
                        _status = _status == _StatusFilter.expired
                            ? _StatusFilter.all
                            : _StatusFilter.expired;
                      }),
                    ),
                    ...categories.map(
                      (c) => _chip(
                        label: c,
                        selected: _category == c,
                        onTap: () => setState(() {
                          _category = _category == c ? null : c;
                        }),
                      ),
                    ),
                    ...members.map(
                      (m) => _chip(
                        label: m,
                        selected: _member == m,
                        onTap: () => setState(() {
                          _member = _member == m ? null : m;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: !widget.repo.loaded
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              docs.isEmpty
                                  ? 'Niciun document adăugat încă.'
                                  : 'Niciun rezultat pentru filtrele alese.',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 15),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 88),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final d = filtered[i];
                              return DocCard(
                                doc: d,
                                settings: settings,
                                onTap: () => _openForm(existing: d),
                                onDelete: () => _confirmDelete(d),
                              );
                            },
                          ),
              ),
              _footer(context),
            ],
          ),
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Legenda(culoare: Color(0xFF1E9E50), text: 'în termen'),
          SizedBox(width: 16),
          _Legenda(culoare: Color(0xFFD97706), text: 'urgent'),
          SizedBox(width: 16),
          _Legenda(culoare: Color(0xFFD93A3A), text: 'expirat'),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.culoare, required this.text});
  final Color culoare;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: culoare, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
