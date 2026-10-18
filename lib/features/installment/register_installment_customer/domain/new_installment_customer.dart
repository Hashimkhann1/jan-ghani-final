/// Register screen ka basic customer data (database: installment_customer).
class NewInstallmentCustomer {
  final String name;
  final String phone;
  final String cnic;
  final String address;

  const NewInstallmentCustomer({
    required this.name,
    required this.phone,
    required this.cnic,
    required this.address,
  });
}
