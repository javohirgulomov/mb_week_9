
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class FakeCheckoutApi extends CheckoutApi {
  @override
  Future<String> submit(double total) async {
    throw const CheckoutException('Card declined');
  }
}

void main() {
  final keyboard = catalog.first;

  group('CartCubit', () {
    blocTest<CartCubit, CartState>(
      'adds products and applies coupon',
      build: () => CartCubit(CheckoutApi()),
      act: (cubit) {
        cubit.add(keyboard);
        cubit.add(keyboard);
        cubit.applyCoupon('SAVE10');
      },
      expect: () => [
        isA<CartState>()
            .having((state) => state.itemCount, 'itemCount', 1)
            .having((state) => state.total, 'total', 49.0)
            .having((state) => state.canUndo, 'canUndo', true),
        isA<CartState>()
            .having((state) => state.itemCount, 'itemCount', 2)
            .having((state) => state.total, 'total', 98.0)
            .having((state) => state.canUndo, 'canUndo', true),
        isA<CartState>()
            .having((state) => state.coupon, 'coupon', 'SAVE10')
            .having((state) => state.total, 'total', 88.2)
            .having((state) => state.canUndo, 'canUndo', true),
      ],
    );

    blocTest<CartCubit, CartState>(
      'checkout emits submitting then failure and keeps cart',
      build: () => CartCubit(FakeCheckoutApi()),
      act: (cubit) async {
        cubit.add(keyboard);
        await cubit.checkout();
      },
      skip: 1,
      expect: () => [
        isA<CartState>()
            .having(
              (state) => state.status,
              'status',
              CheckoutStatus.submitting,
            )
            .having((state) => state.itemCount, 'itemCount', 1),
        isA<CartState>()
            .having(
              (state) => state.status,
              'status',
              CheckoutStatus.failure,
            )
            .having((state) => state.itemCount, 'itemCount', 1)
            .having(
              (state) => state.checkoutError,
              'checkoutError',
              'Card declined',
            ),
      ],
    );
  });
}
