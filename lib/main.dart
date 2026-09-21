import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const DocApp());

/// Un document inregistrat in aplicatie
class Doc {
  final String membru;    // membrul familiei
  final String nume;      // tipul documentului
  final String categorie; // Identitate / Sanatate / Masina / Altele
  final String expira;    // data expirarii, format YYYY-MM-DD

  const Doc({
    required this.membru,
    required this.nume,
    required this.categorie,
    required this.expira,
  });

  // Convertim documentul intr-un obiect JSON (pentru salvare)
  Map<String, dynamic> toJson() =>
      {'n': membru, 'd': nume, 'c': categorie, 'e': expira};

  // Reconstruim documentul din JSON (la incarcare)
  factory Doc.fromJson(Map<String, dynamic> j) => Doc(
        membru: j['n'] as String,
        nume: j['d'] as String,
        categorie: j['c'] as String,
        expira: j['e'] as String,
      );
}

// ---------- Functii ajutatoare (calcule cu datele) ----------

/// Cate zile mai sunt pana la expirare (0 = expira azi, negativ = expirat)
int daysLeft(String expira) {
  final exp = DateTime.parse(expira);
  final azi = DateTime.now();
  final aziMiezulNoptii = DateTime(azi.year, azi.month, azi.day);
  return exp.difference(aziMiezulNoptii).inDays;
}

/// Transforma '2027-01-15' in '15.01.2027'
String fmtData(String iso) {
  final p = iso.split('-');
  return '${p[2]}.${p[1]}.${p[0]}';
}

/// Data de azi + n zile, format YYYY-MM-DD
String dPlus(int n) {
  final d = DateTime.now().add(Duration(days: n));
  return d.toIso8601String().substring(0, 10);
}

/// Documentele de exemplu (ca in versiunea HTML)
List<Doc> dateImplicit() => [
      Doc(membru: 'Maria', nume: 'Buletin de identitate', categorie: 'Identitate', expira: dPlus(420)),
      Doc(membru: 'Andrei', nume: 'Asigurare RCA', categorie: 'Mașină', expira: dPlus(140)),
      Doc(membru: 'Andrei', nume: 'Revizie tehnică ITP', categorie: 'Mașină', expira: dPlus(20)),
      Doc(membru: 'Elena', nume: 'Card de sănătate', categorie: 'Sănătate', expira: dPlus(11)),
      Doc(membru: 'Mihai', nume: 'Permis de conducere', categorie: 'Identitate', expira: dPlus(-5)),
    ];

// ---------- Aplicatia ----------

class DocApp extends StatelessWidget {
  const DocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Documente familie',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // se adapteaza la tema clara/intunecata a sistemului
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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _key = 'famdocs-v1'; // acelasi key ca in localStorage din HTML!

  final _membruCtrl = TextEditingController();
  final _documentCtrl = TextEditingController();
  String _categorie = 'Identitate';
  DateTime? _dataAleasa;
  List<Doc> _docs = [];

  @override
  void initState() {
    super.initState();
    _incarca(); // citim documentele salvate la pornire
  }

  @override
  void dispose() {
    _membruCtrl.dispose();
    _documentCtrl.dispose();
    super.dispose();
  }

  // ---------- Persistenta (echivalentul localStorage) ----------

  Future<void> _incarca() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    final list = s == null
        ? dateImplicit()
        : (jsonDecode(s) as List)
            .map((e) => Doc.fromJson(e as Map<String, dynamic>))
            .toList();
    setState(() => _docs = list);
  }

  Future<void> _salveaza() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(_docs.map((e) => e.toJson()).toList()));
  }

  // ---------- Actiuni ----------

  Future<void> _alegeData() async {
    final acum = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: acum,
      firstDate: DateTime(acum.year - 1),
      lastDate: DateTime(acum.year + 30),
    );
    if (d != null) setState(() => _dataAleasa = d);
  }

  void _adauga() {
    if (_membruCtrl.text.trim().isEmpty ||
        _documentCtrl.text.trim().isEmpty ||
        _dataAleasa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completeaza toate campurile!')),
      );
      return;
    }
    setState(() {
      _docs.add(Doc(
        membru: _membruCtrl.text.trim(),
        nume: _documentCtrl.text.trim(),
        categorie: _categorie,
        expira: _dataAleasa!.toIso8601String().substring(0, 10),
      ));
      _membruCtrl.clear();
      _documentCtrl.clear();
      _dataAleasa = null;
    });
    _salveaza();
  }

  Future<void> _sterge(Doc d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stergi documentul?'),
        content: Text('"${d.nume}" al lui ${d.membru}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuleaza'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sterge'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _docs.remove(d));
      _salveaza();
    }
  }

  // ---------- Culori (ca in CSS-ul original) ----------

  Color _culoare(bool ok) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (ok) return dark ? const Color(0xFF3ECF72) : const Color(0xFF1E9E50);
    return dark ? const Color(0xFFFF6B6B) : const Color(0xFFD93A3A);
  }

  // ---------- Interfata ----------

  @override
  Widget build(BuildContext context) {
    final urgent = _docs.where((d) => daysLeft(d.expira) <= 30).length;
    final sorted = _docs.toList()
      ..sort((a, b) => a.expira.compareTo(b.expira));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documente familie'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_docs.length} documente · $urgent necesita atentie',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _formular(),
          Expanded(
            child: sorted.isEmpty
                ? const Center(
                    child: Text(
                      'Niciun document adaugat inca.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) => _rand(sorted[i]),
                  ),
          ),
          _footer(),
        ],
      ),
    );
  }

  Widget _formular() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _membruCtrl,
              decoration: const InputDecoration(
                labelText: 'Membru familie',
                hintText: 'ex: Maria',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _documentCtrl,
              decoration: const InputDecoration(
                labelText: 'Document',
                hintText: 'ex: Buletin de identitate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _categorie,
                    decoration: const InputDecoration(
                      labelText: 'Categorie',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Identitate', 'Sănătate', 'Mașină', 'Altele']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _categorie = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _alegeData,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiră la',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dataAleasa == null
                            ? 'Alege data'
                            : fmtData(_dataAleasa!.toIso8601String().substring(0, 10)),
                        style: TextStyle(
                          fontSize: 16,
                          color: _dataAleasa == null
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _adauga,
              child: const Text('Adaugă document'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rand(Doc d) {
    final dl = daysLeft(d.expira);
    final ok = dl > 30;
    final c = _culoare(ok);
    final badgeText = dl < 0
        ? 'Expirat de ${-dl} zile'
        : (dl == 0 ? 'Expiră azi' : '$dl zile');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.nume,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _chip(d.categorie),
                      _chip(d.membru),
                      _chip('expiră ${fmtData(d.expira)}'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: c,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: () => _sterge(d),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legenda(const Color(0xFF1E9E50), 'peste 1 lună'),
          const SizedBox(width: 20),
          _legenda(const Color(0xFFD93A3A), 'sub 1 lună'),
        ],
      ),
    );
  }

  Widget _legenda(Color culoare, String text) {
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
