# DocAlert

Aplicație Flutter pentru evidența documentelor familiei (buletin, RCA, ITP, card de sănătate, permis) și alerte înainte de expirare.

## Funcții

- Listă sortată după data expirării, cu stare în termen / urgent / expirat
- Adăugare, editare, ștergere și reînnoire (6 luni / 1 an / 2 ani)
- Notificări locale (30 / 14 / 7 zile și în ziua expirării, ora configurabilă)
- Filtre după status, categorie și membru; căutare
- Poză atașată la document (stocată local)
- Setări: prag de urgență, membri familie
- Export / import backup JSON

Datele rămân pe dispozitiv (`SharedPreferences` + fișiere locale).

## Rulare

```bash
flutter pub get
flutter run
```

Pe Android, acceptă permisiunea de notificări la prima deschidere (sau din Setări → Activează notificările).
