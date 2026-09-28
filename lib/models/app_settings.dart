class AppSettings {
  /// Sub acest număr de zile documentul e „urgent”.
  final int urgentDays;

  /// Cu câte zile înainte se trimit notificări (0 = în ziua expirării).
  final List<int> notifyDaysBefore;

  final int notifyHour;
  final int notifyMinute;
  final List<String> members;

  const AppSettings({
    required this.urgentDays,
    required this.notifyDaysBefore,
    required this.notifyHour,
    required this.notifyMinute,
    required this.members,
  });

  factory AppSettings.defaults() => const AppSettings(
        urgentDays: 30,
        notifyDaysBefore: [30, 14, 7, 0],
        notifyHour: 9,
        notifyMinute: 0,
        members: [],
      );

  AppSettings copyWith({
    int? urgentDays,
    List<int>? notifyDaysBefore,
    int? notifyHour,
    int? notifyMinute,
    List<String>? members,
  }) {
    return AppSettings(
      urgentDays: urgentDays ?? this.urgentDays,
      notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toJson() => {
        'urgentDays': urgentDays,
        'notifyDaysBefore': notifyDaysBefore,
        'notifyHour': notifyHour,
        'notifyMinute': notifyMinute,
        'members': members,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    final days = (j['notifyDaysBefore'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [30, 14, 7, 0];
    return AppSettings(
      urgentDays: (j['urgentDays'] as num?)?.toInt() ?? 30,
      notifyDaysBefore: days,
      notifyHour: (j['notifyHour'] as num?)?.toInt() ?? 9,
      notifyMinute: (j['notifyMinute'] as num?)?.toInt() ?? 0,
      members: (j['members'] as List?)?.map((e) => '$e').toList() ?? const [],
    );
  }
}
