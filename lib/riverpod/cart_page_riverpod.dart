
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerStatefulWidget {
  const RiverpodCartPage({super.key});

  @override
  ConsumerState<RiverpodCartPage> createState() =>
      _RiverpodCartPageState();
}

class _RiverpodCartPageState
    extends ConsumerState<RiverpodCartPage> {
  final TextEditingController _couponController =
      TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CheckoutStatus>(
      cartProvider.select((state) => state.status),
      (previous, next) {
        if (next == CheckoutStatus.success) {
          final orderId = ref.read(cartProvider).orderId;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order successful: $orderId'),
            ),
          );
        }

        if (next == CheckoutStatus.failure) {
          final error = ref.read(cartProvider).checkoutError;

          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();

          ScaffoldMessenger.of(context).showMaterialBanner(
            MaterialBanner(
              content: Text(error ?? 'Checkout failed'),
              actions: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .hideCurrentMaterialBanner();
                  },
                  child: const Text('DISMISS'),
                ),
              ],
            ),
          );
        }
      },
    );

    final state = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final canUndo = ref.watch(canUndoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: canUndo ? notifier.undo : null,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CartBody(
              lines: state.lines,
              onAdd: notifier.add,
              onRemove: notifier.remove,
              onQtyChanged: notifier.changeQty,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        decoration: const InputDecoration(
                          labelText: 'Coupon code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        notifier.applyCoupon(
                          _couponController.text,
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),

                if (state.couponError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.couponError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                if (state.coupon != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'SAVE10 applied successfully!',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),

          const CartSummaryCard(),

          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    state.lines.isEmpty ||
                            state.status == CheckoutStatus.submitting
                        ? null
                        : notifier.checkout,
                child: state.status == CheckoutStatus.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Checkout'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartSummaryCard extends ConsumerWidget {
  const CartSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      cartProvider.select((state) => state.total),
    );

    final state = ref.read(cartProvider);

    debugPrint('CartSummaryCard rebuilt');

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Items: ${state.itemCount}'),
            Text(
              'Subtotal: ${state.subtotal.toStringAsFixed(2)}',
            ),
            Text(
              'Discount: ${state.discount.toStringAsFixed(2)}',
            ),
            Text(
              'Total: ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
