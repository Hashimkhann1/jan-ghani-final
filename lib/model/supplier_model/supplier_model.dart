

class SupplierModel {
  final String name;
  final String address;
  final String contact;
  final String email;
  final String phone;
  final String? paymentTerms;
  final String? leadTime;      // ← add
  final String? taxId;         // ← add
  final double? rating;
  final bool isArchived;
  final DateTime? addedDate;   // ← add
  final DateTime? updatedDate; // ← add

  const SupplierModel({
    required this.name,
    required this.address,
    required this.contact,
    required this.email,
    required this.phone,
    this.paymentTerms,
    this.leadTime,
    this.taxId,
    this.rating,
    this.isArchived = false,
    this.addedDate,
    this.updatedDate,
  });

  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';
}