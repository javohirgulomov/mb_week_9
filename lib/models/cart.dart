
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({
    required this.product,
    required this.qty,
  });

  final Product product;
  final int qty;

  double get subtotal => product.price * qty;

  CartLine copyWith({int? qty}) {
    return CartLine(
      product: product,
      qty: qty ?? this.qty,
    );
  }
}

extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product product) {
    final index = indexWhere((line) => line.product.id == product.id);

    if (index == -1) {
      return [...this, CartLine(product: product, qty: 1)];
    }

    return [
      for (final line in this)
        line.product.id == product.id
            ? line.copyWith(qty: line.qty + 1)
            : line,
    ];
  }

  List<CartLine> without(String productId) {
    return [
      for (final line in this)
        if (line.product.id != productId) line,
    ];
  }

  List<CartLine> changeQty(String productId, int delta) {
    return [
      for (final line in this)
        if (line.product.id == productId)
          if (line.qty + delta > 0)
            line.copyWith(qty: line.qty + delta),
    ];
  }

  double get subtotal {
    return fold(0, (sum, line) => sum + line.subtotal);
  }

  int get itemCount {
    return fold(0, (sum, line) => sum + line.qty);
  }
}

enum CheckoutStatus {
  idle,
  submitting,
  success,
  failure,
}

class CartState {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.canUndo = false,
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;
  final bool canUndo;

  double get subtotal => lines.subtotal;

  int get itemCount => lines.itemCount;

  double get discount {
    return coupon == 'SAVE10' ? subtotal * 0.10 : 0;
  }

  double get total => subtotal - discount;

  CartState copyWith({
    List<CartLine>? lines,
    String? coupon,
    bool clearCoupon = false,
    String? couponError,
    bool clearCouponError = false,
    CheckoutStatus? status,
    String? orderId,
    bool clearOrderId = false,
    String? checkoutError,
    bool clearCheckoutError = false,
    bool? canUndo,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
      couponError: clearCouponError
          ? null
          : (couponError ?? this.couponError),
      status: status ?? this.status,
      orderId: clearOrderId ? null : (orderId ?? this.orderId),
      checkoutError: clearCheckoutError
          ? null
          : (checkoutError ?? this.checkoutError),
      canUndo: canUndo ?? this.canUndo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! CartState) return false;
    if (lines.length != other.lines.length) return false;

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].product.id != other.lines[i].product.id ||
          lines[i].qty != other.lines[i].qty) {
        return false;
      }
    }

    return coupon == other.coupon &&
        couponError == other.couponError &&
        status == other.status &&
        orderId == other.orderId &&
        checkoutError == other.checkoutError &&
        canUndo == other.canUndo;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(
        lines.map((line) => Object.hash(line.product.id, line.qty)),
      ),
      coupon,
      couponError,
      status,
      orderId,
      checkoutError,
      canUndo,
    );
  }
}
