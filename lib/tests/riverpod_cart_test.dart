
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class FakeCheckoutApi implements CheckoutApi {
  @override
  Future<String> submit(double total) async {
    throw const CheckoutException('Card declined');
  }
}

void main() {
  test('Adding products and applying coupon updates total', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final cart = container.read(cartProvider.notifier);

    cart.add(catalog[0]);
    cart.add(catalog[0]);
    cart.applyCoupon('SAVE10');

    expect(
      container.read(cartProvider).total,
      88.2,
    );
  });

  test('Checkout failure keeps cart items', () async {
    final fakeApi = FakeCheckoutApi();

    final container = ProviderContainer(
      overrides: [
        checkoutApiProvider.overrideWithValue(fakeApi),
      ],
    );

    addTearDown(container.dispose);

    final cart = container.read(cartProvider.notifier);

    cart.add(catalog[0]);

    await cart.checkout();

    final state = container.read(cartProvider);

    expect(state.status, CheckoutStatus.failure);
    expect(state.lines.length, 1);
    expect(state.lines.first.product.name, 'Keyboard');
    expect(state.checkoutError, 'Card declined');
  });
}
