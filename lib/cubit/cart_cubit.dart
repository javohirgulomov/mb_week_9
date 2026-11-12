
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());

  final CheckoutApi _api;

  final List<CartState> _history = [];

  void _update(CartState next) {
    if (next == state) return;

    _history.add(state);

    emit(
      next.copyWith(
        canUndo: true,
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
      ),
    );
  }

  void add(Product product) {
    _update(state.copyWith(
      lines: state.lines.withProduct(product),
      clearCouponError: true,
    ));
  }

  void remove(String productId) {
    _update(state.copyWith(
      lines: state.lines.without(productId),
    ));
  }

  void changeQty(String productId, int delta) {
    _update(state.copyWith(
      lines: state.lines.changeQty(productId, delta),
    ));
  }

  void applyCoupon(String code) {
    final value = code.trim().toUpperCase();

    if (value == 'SAVE10') {
      _update(state.copyWith(
        coupon: value,
        clearCouponError: true,
      ));
    } else {
      _update(state.copyWith(
        clearCoupon: true,
        couponError: 'Invalid coupon code',
      ));
    }
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty ||
        state.status == CheckoutStatus.submitting) {
      return;
    }

    emit(state.copyWith(
      status: CheckoutStatus.submitting,
      clearCheckoutError: true,
    ));

    try {
      final orderId = await _api.submit(state.total);

      if (isClosed) return;

      _history.add(
        state.copyWith(status: CheckoutStatus.idle),
      );

      emit(CartState(
        status: CheckoutStatus.success,
        orderId: orderId,
        canUndo: true,
      ));
    } on CheckoutException catch (error) {
      if (isClosed) return;

      emit(state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: error.message,
      ));
    }
  }

  void undo() {
    if (_history.isEmpty) return;

    final previous = _history.removeLast();

    emit(previous.copyWith(
      canUndo: _history.isNotEmpty,
      status: CheckoutStatus.idle,
      clearOrderId: true,
      clearCheckoutError: true,
    ));
  }

  @override
  void onChange(Change<CartState> change) {
    super.onChange(change);
    debugPrint('Cubit state: ${change.currentState} -> ${change.nextState}');
  }
}
