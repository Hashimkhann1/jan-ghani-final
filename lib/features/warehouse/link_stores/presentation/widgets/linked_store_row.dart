import 'package:flutter/material.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/data/models/linked_store_model/linked_store_model.dart';



class LinkedStoreRow extends StatelessWidget {
  final LinkedStoreModel store;
  final int index;

  const LinkedStoreRow({
    super.key,
    required this.store,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          _cell(store.storeCode, flex: 2),
          _cell(store.storeName, flex: 3),
          _cell(store.storePhone ?? '-', flex: 2),
          _cell(store.managerName ?? '-', flex: 2),
          _cell(store.storeAddress ?? '-', flex: 3),
          _statusCell(store.isActive),
        ],
      ),
    );
  }

  Widget _cell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statusCell(bool isActive) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}