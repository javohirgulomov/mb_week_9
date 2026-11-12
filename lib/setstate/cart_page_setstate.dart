
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import '../services/checkout_api.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key});

  @override
  State<SetStateCartPage> createState() =>
      _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  CartState _state = const CartState();

  final List<CartState> _history = [];

  final CheckoutApi _api = CheckoutApi();

  final TextEditingController _couponController =
      TextEditingController();

  void _saveHistory() {
    _history.add(_state);
  }

  void _add(Product product) {
    setState(() {
      _saveHistory();

      _state = _state.copyWith(
        lines: _state.lines.withProduct(product),
        clearCouponError: true,
      );
    });
  }

  void _remove(String id) {
    setState(() {
      _saveHistory();

      _state = _state.copyWith(
        lines: _state.lines.without(id),
      );
    });
  }

  void _changeQty(String id, int delta) {
    setState(() {
      _saveHistory();

      _state = _state.copyWith(
        lines: _state.lines.changeQty(id, delta),
      );
    });
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();

    setState(() {
      _saveHistory();

      if (code == 'SAVE10') {
        _state = _state.copyWith(
          coupon: code,
          clearCouponError: true,
        );
      } else {
        _state = _state.copyWith(
          clearCoupon: true,
          couponError: 'Invalid coupon code',
        );
      }
    });
  }

  void _undo() {
    if (_history.isEmpty) return;

    setState(() {
      _state = _history.removeLast();
    });
  }

  Future<void> _checkout() async {
    if (_state.lines.isEmpty ||
        _state.status == CheckoutStatus.submitting) {
      return;
    }

    final total = _state.total;

    setState(() {
      _state = _state.copyWith(
        status: CheckoutStatus.submitting,
        clearCheckoutError: true,
      );
    });

    try {
      final orderId = await _api.submit(total);

      if (!mounted) return;

      setState(() {
        _history.add(
          _state.copyWith(
            status: CheckoutStatus.idle,
            clearOrderId: true,
            clearCheckoutError: true,
          ),
        );

        _state = _state.copyWith(
          lines: const [],
          clearCoupon: true,
          clearCouponError: true,
          status: CheckoutStatus.success,
          orderId: orderId,
          clearCheckoutError: true,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order successful: $orderId'),
        ),
      );
    } on CheckoutException catch (e) {
      if (!mounted) return;

      setState(() {
        _state = _state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: e.message,
        );
      });
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · setState'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CartBody(
              lines: _state.lines,
              onAdd: _add,
              onRemove: _remove,
              onQtyChanged: _changeQty,
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
                      onPressed: _applyCoupon,
                      child: const Text('Apply'),
                    ),
                  ],
                ),

                if (_state.couponError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _state.couponError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                if (_state.coupon != null)
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

          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Items: ${_state.itemCount}'),
                  Text(
                    'Subtotal: ${_state.subtotal.toStringAsFixed(2)}',
                  ),
                  Text(
                    'Discount: ${_state.discount.toStringAsFixed(2)}',
                  ),
                  Text(
                    'Total: ${_state.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_state.status == CheckoutStatus.failure)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: MaterialBanner(
                content: Text(
                  _state.checkoutError ?? 'Checkout failed',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _state = _state.copyWith(
                          status: CheckoutStatus.idle,
                          clearCheckoutError: true,
                        );
                      });
                    },
                    child: const Text('DISMISS'),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _state.lines.isEmpty ||
                            _state.status == CheckoutStatus.submitting
                        ? null
                        : _checkout,
                child: _state.status == CheckoutStatus.submitting
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
