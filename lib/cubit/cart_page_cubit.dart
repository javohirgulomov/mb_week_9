
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatefulWidget {
  const CubitCartPage({super.key});

  @override
  State<CubitCartPage> createState() => _CubitCartPageState();
}

class _CubitCartPageState extends State<CubitCartPage> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartCubit(CheckoutApi()),
      child: Builder(
        builder: (context) {
          final cubit = context.read<CartCubit>();

          return BlocListener<CartCubit, CartState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == CheckoutStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order placed: ${state.orderId}'),
                  ),
                );
              }

              if (state.status == CheckoutStatus.failure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentMaterialBanner()
                  ..showMaterialBanner(
                    MaterialBanner(
                      content: Text(
                        state.checkoutError ?? 'Checkout failed',
                      ),
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
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Cart · Cubit'),
                actions: [
                  BlocBuilder<CartCubit, CartState>(
                    buildWhen: (previous, current) =>
                        previous.canUndo != current.canUndo,
                    builder: (context, state) {
                      return IconButton(
                        tooltip: 'Undo',
                        onPressed:
                            state.canUndo ? cubit.undo : null,
                        icon: const Icon(Icons.undo),
                      );
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: BlocBuilder<CartCubit, CartState>(
                      builder: (context, state) {
                        return CartBody(
                          lines: state.lines,
                          onAdd: cubit.add,
                          onRemove: cubit.remove,
                          onQtyChanged: cubit.changeQty,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _couponController,
                          decoration: const InputDecoration(
                            labelText: 'Coupon code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<CartCubit, CartState>(
                          buildWhen: (previous, current) =>
                              previous.couponError != current.couponError,
                          builder: (context, state) {
                            if (state.couponError == null) {
                              return const SizedBox.shrink();
                            }

                            return Text(
                              state.couponError!,
                              style: const TextStyle(color: Colors.red),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              cubit.applyCoupon(_couponController.text);
                            },
                            child: const Text('Apply coupon'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const CartSummaryCard(),
                        const SizedBox(height: 12),
                        BlocBuilder<CartCubit, CartState>(
                          buildWhen: (previous, current) =>
                              previous.status != current.status ||
                              previous.lines != current.lines,
                          builder: (context, state) {
                            final loading =
                                state.status == CheckoutStatus.submitting;

                            return SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: loading || state.lines.isEmpty
                                    ? null
                                    : cubit.checkout,
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Checkout'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, double>(
      selector: (state) => state.total,
      builder: (context, total) {
        debugPrint('CartSummaryCard rebuilt');

        final state = context.read<CartCubit>().state;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('Items', '${state.itemCount}'),
                _row('Subtotal', state.subtotal.toStringAsFixed(2)),
                _row('Discount', state.discount.toStringAsFixed(2)),
                const Divider(),
                _row('Total', total.toStringAsFixed(2)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}
