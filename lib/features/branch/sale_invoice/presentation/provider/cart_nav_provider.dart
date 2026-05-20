// lib/features/branch/sale_invoice/presentation/provider/cart_nav_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Columns: 0=Qty, 1=Price, 2=Discount, 3=SubTotal(read-only)
class CartNavState {
  final bool isActive;
  final int  row;
  final int  col;

  static const int colCount        = 4; // ✅ 5 tha, Tax hata ke 4 kiya
  static const int colSubTotal     = 3;
  static const int lastEditableCol = 2; // ✅ NEW — Discount = last editable

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

  // ✅ Tax hata diya — cart mein sirf yeh 4 columns hain
  static const colLabels = ['Qty', 'Price', 'Discount', 'SubTotal'];
}

class CartNavNotifier extends StateNotifier<CartNavState> {
  CartNavNotifier() : super(const CartNavState());

  void activate(int totalRows) {
    if (totalRows == 0) return;
    state = CartNavState(isActive: true, row: 0, col: 0);
  }

  void deactivate() => state = const CartNavState();

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

  // ✅ NEW — Discount submit hone pe nav end karo taake total update ho
  bool confirmAndMoveOn(int totalRows) {
    if (!state.isActive) return false;

    if (state.col >= CartNavState.lastEditableCol) {
      deactivate();
      return true;
    }

    moveRight();
    return false;
  }
}

final cartNavProvider =
StateNotifierProvider<CartNavNotifier, CartNavState>(
      (ref) => CartNavNotifier(),
);