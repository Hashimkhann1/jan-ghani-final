import 'package:jan_ghani_final/features/branch/counter/data/model/counter_model.dart';

class UserModel {
  final String   id;
  final String   storeId;
  final String   username;
  final String   passwordHash;
  final String   fullName;
  final String?  phone;
  final String   role;
  final bool     isActive;
  final String?  counterId;   // ← new
  final DateTime?  lastLogin;
  final DateTime   createdAt;
  final DateTime   updatedAt;
  final DateTime?  deletedAt;

  const UserModel({
    required this.id,
    required this.storeId,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    this.counterId,            // ← new
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isOwner      => role == 'store_owner';
  bool get isManager    => role == 'store_manager';
  bool get isCashier    => role == 'cashier';
  bool get isStock      => role == 'stock_officer';
  bool get hasCounter   => counterId != null; // ← new

  String get roleLabel {
    switch (role) {
      case 'store_owner':   return 'Owner';
      case 'store_manager': return 'Manager';
      case 'stock_officer': return 'Stock Officer';
      default:              return 'Cashier';
    }
  }

  String get lastLoginLabel {
    if (lastLogin == null) return 'Never';
    final diff = DateTime.now().difference(lastLogin!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id:           _str(map['id'])            ?? '',
      storeId:      _str(map['store_id'])      ?? '',
      username:     _str(map['username'])      ?? '',
      passwordHash: _str(map['password_hash']) ?? '',
      fullName:     _str(map['full_name'])     ?? '',
      phone:        _str(map['phone']),
      role:         _str(map['role'])          ?? 'cashier',
      isActive:     map['is_active'] as bool?  ?? true,
      counterId:    _str(map['counter_id']),   // ← new
      lastLogin:    _date(map['last_login']),
      createdAt:    _date(map['created_at'])   ?? DateTime.now(),
      updatedAt:    _date(map['updated_at'])   ?? DateTime.now(),
      deletedAt:    _date(map['deleted_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'store_id':      storeId,
    'username':      username,
    'password_hash': passwordHash,
    'full_name':     fullName,
    'phone':         phone,
    'role':          role,
    'is_active':     isActive,
    'counter_id':    counterId,  // ← new
  };

  UserModel copyWith({
    String?   username,
    String?   passwordHash,
    String?   fullName,
    String?   phone,
    String?   role,
    bool?     isActive,
    String?   counterId,         // ← new
    bool      clearCounter = false, // ← null set karne ke liye
    DateTime? lastLogin,
  }) {
    return UserModel(
      id:           id,
      storeId:      storeId,
      username:     username     ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName:     fullName     ?? this.fullName,
      phone:        phone        ?? this.phone,
      role:         role         ?? this.role,
      isActive:     isActive     ?? this.isActive,
      counterId:    clearCounter ? null : (counterId ?? this.counterId),
      lastLogin:    lastLogin    ?? this.lastLogin,
      createdAt:    createdAt,
      updatedAt:    DateTime.now(),
      deletedAt:    deletedAt,
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
      identical(this, other) ||
          other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserModel(id: $id, username: $username, role: $role, counterId: $counterId)';
}