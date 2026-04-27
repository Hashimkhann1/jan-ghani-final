// lib/features/branch/sale_invoice/presentation/provider/cart_nav_provider.dart
// Cart keyboard navigation state

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Columns: 0=Qty, 1=Price, 2=Tax, 3=Discount, 4=SubTotal
class CartNavState {
  final bool isActive;
  final int  row;
  final int  col;

  static const int colCount = 5;

  const CartNavState({
    this.isActive = false,
    this.row      = 0,
    this.col      = 0,
  });

  CartNavState copyWith({bool? isActive, int? row, int? col}) => CartNavState(
    isActive: isActive ?? this.isActive,
    row:      row      ?? this.row,
    col:      col      ?? this.col,
  );

  static const colLabels = ['Qty', 'Price', 'Tax', 'Discount', 'SubTotal'];
}

class CartNavNotifier extends StateNotifier<CartNavState> {
  CartNavNotifier() : super(const CartNavState());

  void activate(int totalRows) {
    if (totalRows == 0) return;
    state = CartNavState(isActive: true, row: 0, col: 0);
  }

  void deactivate() => state = const CartNavState();

  // ✅ NEW: Mouse click pe yeh call karo — nav state sync ho jaata hai
  // Taki arrow keys sahi position se start hon
  void jumpTo(int row, int col) {
    state = CartNavState(isActive: true, row: row, col: col);
  }

  void moveDown(int totalRows) {
    if (!state.isActive || totalRows == 0) return;
    final next = (state.row + 1).clamp(0, totalRows - 1);
    state = state.copyWith(row: next);
  }

  void moveUp() {
    if (!state.isActive) return;
    final prev = (state.row - 1).clamp(0, 999);
    state = state.copyWith(row: prev);
  }

  void moveRight() {
    if (!state.isActive) return;
    final next = (state.col + 1).clamp(0, CartNavState.colCount - 1);
    state = state.copyWith(col: next);
  }

  void moveLeft() {
    if (!state.isActive) return;
    final prev = (state.col - 1).clamp(0, CartNavState.colCount - 1);
    state = state.copyWith(col: prev);
  }
}

final cartNavProvider =
StateNotifierProvider<CartNavNotifier, CartNavState>(
      (ref) => CartNavNotifier(),
);