class CounterModel {
  final String   id;
  final String   storeId;
  final String   counterName;
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final DateTime? deletedAt;

  const CounterModel({
    required this.id,
    required this.storeId,
    required this.counterName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory CounterModel.fromMap(Map<String, dynamic> map) {
    return CounterModel(
      id:          _str(map['id'])          ?? '',
      storeId:     _str(map['store_id'])    ?? '',
      counterName: _str(map['counter_name']) ?? '',
      createdAt:   _date(map['created_at']) ?? DateTime.now(),
      updatedAt:   _date(map['updated_at']) ?? DateTime.now(),
      deletedAt:   _date(map['deleted_at']),
    );
  }

  CounterModel copyWith({String? counterName}) {
    return CounterModel(
      id:          id,
      storeId:     storeId,
      counterName: counterName ?? this.counterName,
      createdAt:   createdAt,
      updatedAt:   DateTime.now(),
      deletedAt:   deletedAt,
    );
  }

  static String?   _str(dynamic v)  => v?.toString();
  static DateTime? _date(dynamic v) {
    if (v == null)     return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CounterModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}