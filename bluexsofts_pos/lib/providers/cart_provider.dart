import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/sale.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  double _taxRate = 0.0; // Configurable tax rate
  double _discount = 0.0;
  String _paymentMethod = 'CASH';
  String _notes = '';

  List<CartItem> get items => List.unmodifiable(_items);
  double get taxRate => _taxRate;
  double get discount => _discount;
  String get paymentMethod => _paymentMethod;
  String get notes => _notes;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get taxAmount => subtotal * _taxRate;

  double get total => subtotal + taxAmount - _discount;

  bool get isEmpty => _items.isEmpty;

  void addProduct(Product product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      if (_items[index].quantity < product.stock) {
        _items[index].quantity++;
        notifyListeners();
      }
    } else {
      if (product.stock > 0) {
        _items.add(CartItem(product: product));
        notifyListeners();
      }
    }
  }

  void removeProduct(String productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity.clamp(1, _items[index].product.stock);
      }
      notifyListeners();
    }
  }

  void setTaxRate(double rate) {
    _taxRate = rate.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setDiscount(double amount) {
    _discount = amount.clamp(0.0, subtotal);
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setNotes(String n) {
    _notes = n;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discount = 0.0;
    _notes = '';
    _paymentMethod = 'CASH';
    notifyListeners();
  }

  List<Map<String, dynamic>> toSaleItems() {
    return _items.map((item) => item.toJson()).toList();
  }

  Map<String, dynamic> toCheckoutPayload() => {
    'items': toSaleItems(),
    'paymentMethod': _paymentMethod,
    'tax': taxAmount,
    'discount': _discount,
    'notes': _notes,
  };
}
