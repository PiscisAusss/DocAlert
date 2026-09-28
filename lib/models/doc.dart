const kCategorii = ['Identitate', 'Sănătate', 'Mașină', 'Altele'];

class Doc {
  final String id;
  final String membru;
  final String nume;
  final String categorie;
  final String expira;
  final String note;
  final String? imagePath;

  const Doc({
    required this.id,
    required this.membru,
    required this.nume,
    required this.categorie,
    required this.expira,
    this.note = '',
    this.imagePath,
  });

  Doc copyWith({
    String? id,
    String? membru,
    String? nume,
    String? categorie,
    String? expira,
    String? note,
    String? imagePath,
    bool clearImage = false,
  }) {
    return Doc(
      id: id ?? this.id,
      membru: membru ?? this.membru,
      nume: nume ?? this.nume,
      categorie: categorie ?? this.categorie,
      expira: expira ?? this.expira,
      note: note ?? this.note,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': membru,
        'd': nume,
        'c': categorie,
        'e': expira,
        'note': note,
        if (imagePath != null) 'img': imagePath,
      };

  factory Doc.fromJson(Map<String, dynamic> j) {
    final membru = (j['n'] ?? j['membru'] ?? '') as String;
    final nume = (j['d'] ?? j['nume'] ?? '') as String;
    final expira = (j['e'] ?? j['expira'] ?? '') as String;
    return Doc(
      id: (j['id'] as String?) ?? '$membru|$nume|$expira',
      membru: membru,
      nume: nume,
      categorie: (j['c'] ?? j['categorie'] ?? 'Altele') as String,
      expira: expira,
      note: (j['note'] as String?) ?? '',
      imagePath: j['img'] as String?,
    );
  }
}
