// Updated on 2026-10-15 10:24 AM

// =============================================================
// balance_status.dart
// Inventory Balance ka 5-state machine — DB codes + UI display info.
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';

enum BalanceStatus {
  reviewPending,
  branchPending,
  reviewerRejected,
  branchRejected,
  applied;

  static BalanceStatus fromCode(String code) {
    switch (code) {
      case 'review_pending':    return BalanceStatus.reviewPending;
      case 'branch_pending':    return BalanceStatus.branchPending;
      case 'reviewer_rejected': return BalanceStatus.reviewerRejected;
      case 'branch_rejected':   return BalanceStatus.branchRejected;
      case 'applied':           return BalanceStatus.applied;
      default:                  return BalanceStatus.reviewPending;
    }
  }

  String get code {
    switch (this) {
      case BalanceStatus.reviewPending:    return 'review_pending';
      case BalanceStatus.branchPending:    return 'branch_pending';
      case BalanceStatus.reviewerRejected: return 'reviewer_rejected';
      case BalanceStatus.branchRejected:   return 'branch_rejected';
      case BalanceStatus.applied:          return 'applied';
    }
  }

  String get label {
    switch (this) {
      case BalanceStatus.reviewPending:    return 'Review Pending';
      case BalanceStatus.branchPending:    return 'Pending';
      case BalanceStatus.reviewerRejected: return 'Reviewer Rejected';
      case BalanceStatus.branchRejected:   return 'Branch Rejected';
      case BalanceStatus.applied:          return 'Accepted';
    }
  }

  Color get color {
    switch (this) {
      case BalanceStatus.reviewPending:    return WarehouseAppColor.warningDark;
      case BalanceStatus.branchPending:    return WarehouseAppColor.info;
      case BalanceStatus.reviewerRejected: return WarehouseAppColor.error;
      case BalanceStatus.branchRejected:   return WarehouseAppColor.error;
      case BalanceStatus.applied:          return WarehouseAppColor.success;
    }
  }

  Color get bgColor {
    switch (this) {
      case BalanceStatus.reviewPending:    return WarehouseAppColor.warningLight;
      case BalanceStatus.branchPending:    return WarehouseAppColor.infoLight;
      case BalanceStatus.reviewerRejected: return WarehouseAppColor.errorLight;
      case BalanceStatus.branchRejected:   return WarehouseAppColor.errorLight;
      case BalanceStatus.applied:          return WarehouseAppColor.successLight;
    }
  }

  bool get isTerminal =>
      this == BalanceStatus.reviewerRejected ||
      this == BalanceStatus.branchRejected  ||
      this == BalanceStatus.applied;
}

// Threshold for red-flag high-variance banner (PKR).
const double kHighVarianceRupeeThreshold = 5000;

bool isHighVariance(double delta, double unitPrice) =>
    (delta * unitPrice).abs() > kHighVarianceRupeeThreshold;
