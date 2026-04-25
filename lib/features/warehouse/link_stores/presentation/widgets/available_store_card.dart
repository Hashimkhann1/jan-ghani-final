import 'package:flutter/material.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/data/models/store_model/store_model.dart';

class AvailableStoreCard extends StatelessWidget {
  final StoreModel store;
  final bool isAlreadyLinked;
  final VoidCallback? onLink;

  const AvailableStoreCard({
    super.key,
    required this.store,
    required this.isAlreadyLinked,
    this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isAlreadyLinked ? 0 : 4,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isAlreadyLinked
              ? Colors.grey.shade200
              : Colors.blue.shade100.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: isAlreadyLinked ? Colors.grey.shade50 : Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: isAlreadyLinked
                ? null
                : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50.withOpacity(0.3),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative element
              if (!isAlreadyLinked)
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row with store icon and name
                        Row(
                          children: [
                            // Animated icon container
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: isAlreadyLinked
                                    ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade100,
                                  ],
                                )
                                    : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade600,
                                    Colors.blue.shade400,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: isAlreadyLinked
                                    ? []
                                    : [
                                  BoxShadow(
                                    color: Colors.blue.shade200,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 24,
                                color: isAlreadyLinked
                                    ? Colors.grey.shade500
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.storeName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isAlreadyLinked
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade900,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      store.storeCode,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAlreadyLinked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade50,
                                      Colors.green.shade100,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.green.shade300, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade200,
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 14, color: Colors.green.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Linked',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Divider with gradient
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.shade300,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Info section with better styling
                        if (store.storePhone != null)
                          _infoRow(
                            Icons.phone_android_rounded,
                            store.storePhone!,
                            isAlreadyLinked,
                          ),
                        if (store.storeAddress != null)
                          _infoRow(
                            Icons.location_on_rounded,
                            store.storeAddress!,
                            isAlreadyLinked,
                          ),


                        const SizedBox(height: 16),

                        // Button with animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 42,
                          child: isAlreadyLinked
                              ? _buildLinkedButton()
                              : _buildLinkButton(),
                        ),
                      ],
                    ),
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isAlreadyLinked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isAlreadyLinked
                  ? Colors.grey.shade100
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isAlreadyLinked
                  ? Colors.grey.shade500
                  : Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: isAlreadyLinked
                    ? Colors.grey.shade500
                    : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton() {
    return ElevatedButton(
      onPressed: onLink,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.blue.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link_rounded, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Link Store',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 1.5),
        color: Colors.green.shade50,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Colors.green,
          ),
          SizedBox(width: 8),
          Text(
            'Already Linked',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}