
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>(
  (ref) => CheckoutApi(),
);

class CartNotifier extends Notifier<CartState> {
  final List<CartState> _history = [];

  @override
  CartState build() {
    return const CartState();
  }

  bool get canUndo => _history.isNotEmpty;

  void _update(CartState next) {
    if (next == state) return;

    _history.add(state);
    state = next;
  }

  void add(Product product) {
    _update(
      state.copyWith(
        lines: state.lines.withProduct(product),
        clearCouponError: true,
      ),
    );
  }

  void remove(String id) {
    _update(
      state.copyWith(
        lines: state.lines.without(id),
      ),
    );
  }

  void changeQty(String id, int delta) {
    _update(
      state.copyWith(
        lines: state.lines.changeQty(id, delta),
      ),
    );
  }

  void applyCoupon(String code) {
    final normalized = code.trim().toUpperCase();

    if (normalized == 'SAVE10') {
      _update(
        state.copyWith(
          coupon: normalized,
          clearCouponError: true,
        ),
      );
    } else {
      _update(
        state.copyWith(
          clearCoupon: true,
          couponError: 'Invalid coupon code',
        ),
      );
    }
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty ||
        state.status == CheckoutStatus.submitting) {
      return;
    }

    final previousState = state;
    final total = state.total;
    final api = ref.read(checkoutApiProvider);

    state = state.copyWith(
      status: CheckoutStatus.submitting,
      clearCheckoutError: true,
    );

    try {
      final orderId = await api.submit(total);

      _history.add(previousState);

      state = state.copyWith(
        lines: const [],
        clearCoupon: true,
        clearCouponError: true,
        status: CheckoutStatus.success,
        orderId: orderId,
        clearCheckoutError: true,
      );
    } on CheckoutException catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      );
    }
  }

  void undo() {
    if (_history.isEmpty) return;

    state = _history.removeLast();
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

final canUndoProvider = Provider<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});
