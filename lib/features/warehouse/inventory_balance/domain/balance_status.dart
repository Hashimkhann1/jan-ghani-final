// =============================================================
// balance_status.dart
// Inventory Balance ka 5-state machine — DB codes + UI display info.
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

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
      case BalanceStatus.reviewPending:    return AppColor.warningDark;
      case BalanceStatus.branchPending:    return AppColor.info;
      case BalanceStatus.reviewerRejected: return AppColor.error;
      case BalanceStatus.branchRejected:   return AppColor.error;
      case BalanceStatus.applied:          return AppColor.success;
    }
  }

  Color get bgColor {
    switch (this) {
      case BalanceStatus.reviewPending:    return AppColor.warningLight;
      case BalanceStatus.branchPending:    return AppColor.infoLight;
      case BalanceStatus.reviewerRejected: return AppColor.errorLight;
      case BalanceStatus.branchRejected:   return AppColor.errorLight;
      case BalanceStatus.applied:          return AppColor.successLight;
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
