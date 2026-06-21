import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_summary.dart';

/// NOTE: Yeh sirf UI ke liye mock data hai. Baad mein yahan postgres /
/// Supabase datasource aayega — abhi koi DB connection nahi.

const InstallmentSummary kInstallmentSummaryMock = InstallmentSummary(
  totalCustomers: 1284,
  customersGrowthPct: 12,
  activeCount: 842,
  remainingTotal: 4200000,
  collectedThisMonth: 1800000,
);

final List<InstallmentCustomer> kInstallmentCustomersMock = [
  // Multi-plan customer: ek product abhi, doosra ~3 mahine baad liya.
  InstallmentCustomer(
    id: '1',
    name: 'Arjun Sharma',
    phone: '+92 300 1234567',
    cnic: '42101-1234567-1',
    plans: [
      InstallmentPlan(
        id: '1a',
        product: 'iPhone 15 Pro Max (Titanium)',
        totalPayable: 90000,
        paidAmount: 45000,
        paidCount: 6,
        totalCount: 12,
        status: InstallmentStatus.active,
        startDate: DateTime(2026, 1, 10),
      ),
      InstallmentPlan(
        id: '1b',
        product: 'AirPods Pro 2',
        totalPayable: 60000,
        paidAmount: 10000,
        paidCount: 1,
        totalCount: 6,
        status: InstallmentStatus.active,
        startDate: DateTime(2026, 4, 15),
      ),
    ],
  ),
  InstallmentCustomer(
    id: '2',
    name: 'Priya Kapur',
    phone: '+92 301 2345678',
    cnic: '42201-2345678-2',
    plans: [
      InstallmentPlan(
        id: '2a',
        product: 'MacBook Air M2 (Silver)',
        totalPayable: 110000,
        paidAmount: 27500,
        paidCount: 3,
        totalCount: 10,
        status: InstallmentStatus.overdue,
        startDate: DateTime(2026, 2, 5),
      ),
    ],
  ),
  InstallmentCustomer(
    id: '3',
    name: 'Rajesh Varma',
    phone: '+92 302 3456789',
    cnic: '42301-3456789-3',
    plans: [
      InstallmentPlan(
        id: '3a',
        product: 'Sony Bravia 55" OLED',
        totalPayable: 95000,
        paidAmount: 95000,
        paidCount: 12,
        totalCount: 12,
        status: InstallmentStatus.completed,
        startDate: DateTime(2025, 6, 1),
      ),
    ],
  ),
  InstallmentCustomer(
    id: '4',
    name: 'Javed Malik',
    phone: '+92 303 4567890',
    cnic: '42401-4567890-4',
    plans: [
      InstallmentPlan(
        id: '4a',
        product: 'Samsung S24 Ultra',
        totalPayable: 150000,
        paidAmount: 30000,
        paidCount: 2,
        totalCount: 9,
        status: InstallmentStatus.active,
        startDate: DateTime(2026, 5, 1),
      ),
    ],
  ),
  InstallmentCustomer(
    id: '5',
    name: 'M Hashim',
    phone: '+92 304 5678901',
    cnic: '42501-5678901-5',
    plans: [
      InstallmentPlan(
        id: '5a',
        product: 'Dell XPS 15 Laptop',
        totalPayable: 96000,
        paidAmount: 32000,
        paidCount: 4,
        totalCount: 8,
        status: InstallmentStatus.overdue,
        startDate: DateTime(2026, 3, 20),
      ),
    ],
  ),
];
