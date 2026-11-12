
import 'package:flutter/material.dart';
import '../models/cart.dart';

class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.onAdd,
    required this.onRemove,
    required this.onQtyChanged,
  });

  final List<CartLine> lines;
  final void Function(Product) onAdd;
  final void Function(String) onRemove;
  final void Function(String, int) onQtyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final p in catalog)
                ActionChip(
                  label: Text(
                    '${p.name} · ${p.price.toStringAsFixed(0)}',
                  ),
                  onPressed: () => onAdd(p),
                ),
            ],
          ),
        ),
        Expanded(
          child: lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(
                  children: [
                    for (final line in lines)
                      ListTile(
                        key: ValueKey(line.product.id),
                        title: Text(line.product.name),
                        subtitle: Text(
                          'Price: ${line.product.price.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => onQtyChanged(
                                line.product.id,
                                -1,
                              ),
                            ),
                            Text('${line.qty}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => onQtyChanged(
                                line.product.id,
                                1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
