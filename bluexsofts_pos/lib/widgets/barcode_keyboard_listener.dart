import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';

class BarcodeKeyboardListener extends StatefulWidget {
  final Widget child;

  const BarcodeKeyboardListener({super.key, required this.child});

  @override
  State<BarcodeKeyboardListener> createState() => _BarcodeKeyboardListenerState();
}

class _BarcodeKeyboardListenerState extends State<BarcodeKeyboardListener> {
  final _buffer = StringBuffer();
  Timer? _resetTimer;
  static const _maxInterval = Duration(milliseconds: 100);
  static const _minLength = 5;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleKey(String char) {
    _buffer.write(char);
    _resetTimer?.cancel();
    _resetTimer = Timer(_maxInterval, _processBuffer);
  }

  Future<void> _processBuffer() async {
    final code = _buffer.toString().trim();
    _buffer.clear();

    if (code.length < _minLength) return;

    if (!mounted) return;
    final productProv = context.read<ProductProvider>();
    final cart = context.read<CartProvider>();

    final product = await productProv.findProductByBarcode(code);
    if (!mounted) return;

    if (product != null) {
      cart.addProduct(product);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned: ${product.name} added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool get _isTextInputFocused {
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context == null) return false;
    return focus!.context!.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        // Don't consume keys when a text field is focused — let it type normally
        if (_isTextInputFocused) return KeyEventResult.ignored;

        if (event is KeyDownEvent) {
          final logical = event.logicalKey;

          if (logical == LogicalKeyboardKey.enter ||
              logical == LogicalKeyboardKey.numpadEnter) {
            _processBuffer();
            return KeyEventResult.handled;
          }

          final char = _keyToChar(logical);
          if (char != null) {
            _handleKey(char);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }

  String? _keyToChar(LogicalKeyboardKey key) {
    if (key.keyLabel.length == 1) return key.keyLabel;
    if (key == LogicalKeyboardKey.numpad0) return '0';
    if (key == LogicalKeyboardKey.numpad1) return '1';
    if (key == LogicalKeyboardKey.numpad2) return '2';
    if (key == LogicalKeyboardKey.numpad3) return '3';
    if (key == LogicalKeyboardKey.numpad4) return '4';
    if (key == LogicalKeyboardKey.numpad5) return '5';
    if (key == LogicalKeyboardKey.numpad6) return '6';
    if (key == LogicalKeyboardKey.numpad7) return '7';
    if (key == LogicalKeyboardKey.numpad8) return '8';
    if (key == LogicalKeyboardKey.numpad9) return '9';
    return null;
  }
}
