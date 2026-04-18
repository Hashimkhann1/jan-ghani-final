class UserModel {
  final String    id;
  final String    warehouseId;   // warehouse_id — warehouses table reference
  final String    username;
  final String    passwordHash;
  final String    fullName;
  final String?   phone;
  final String    role;          // warehouse_owner | warehouse_manager | warehouse_staff | data_entry
  final bool      isActive;
  final DateTime? lastLogin;
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final DateTime? deletedAt;

  const UserModel({
    required this.id,
    required this.warehouseId,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ── Role helpers ──────────────────────────────────────────
  bool get isOwner   => role == 'warehouse_owner';
  bool get isManager => role == 'warehouse_manager';
  bool get isStaff   => role == 'warehouse_staff';
  bool get isEntry   => role == 'data_entry';

  String get roleLabel {
    switch (role) {
      case 'warehouse_owner':   return 'Owner';
      case 'warehouse_manager': return 'Manager';
      case 'warehouse_staff':   return 'Staff';
      case 'data_entry':        return 'Data Entry';
      default:                  return role;
    }
  }

  String get lastLoginLabel {
    if (lastLogin == null) return 'Never';
    final diff = DateTime.now().difference(lastLogin!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── fromMap ───────────────────────────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id:           _str(map['id'])            ?? '',
      warehouseId:  _str(map['warehouse_id'])  ?? '',
      username:     _str(map['username'])      ?? '',
      passwordHash: _str(map['password_hash']) ?? '',
      fullName:     _str(map['full_name'])     ?? '',
      phone:        _str(map['phone']),
      role:         _str(map['role'])          ?? 'warehouse_staff',
      isActive:     map['is_active'] == true ||
                    map['is_active'] == 't',
      lastLogin:    _date(map['last_login']),
      createdAt:    _date(map['created_at'])   ?? DateTime.now(),
      updatedAt:    _date(map['updated_at'])   ?? DateTime.now(),
      deletedAt:    _date(map['deleted_at']),
    );
  }

  // ── toMap ─────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'warehouse_id':  warehouseId,
    'username':      username,
    'password_hash': passwordHash,
    'full_name':     fullName,
    'phone':         phone,
    'role':          role,
    'is_active':     isActive,
  };

  // ── copyWith ──────────────────────────────────────────────
  UserModel copyWith({
    String?   username,
    String?   passwordHash,
    String?   fullName,
    String?   phone,
    String?   role,
    bool?     isActive,
    DateTime? lastLogin,
    DateTime? deletedAt,
  }) {
    return UserModel(
      id:           id,
      warehouseId:  warehouseId,
      username:     username     ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName:     fullName     ?? this.fullName,
      phone:        phone        ?? this.phone,
      role:         role         ?? this.role,
      isActive:     isActive     ?? this.isActive,
      lastLogin:    lastLogin    ?? this.lastLogin,
      createdAt:    createdAt,
      updatedAt:    DateTime.now(),
      deletedAt:    deletedAt    ?? this.deletedAt,
    );
  }

  // ── Safe parsers ──────────────────────────────────────────
  static String?   _str(dynamic v) => v?.toString();
  static DateTime? _date(dynamic v) {
    if (v == null)     return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserModel(id: $id, username: $username, role: $role)';
}
