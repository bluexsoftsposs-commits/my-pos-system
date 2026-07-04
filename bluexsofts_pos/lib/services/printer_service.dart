import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../core/currency_formatter.dart';

enum PrinterType { simple, wifi }

class PrinterConfig {
  final PrinterType type;
  final String? bluetoothMac;
  final String? wifiIp;
  final int wifiPort;
  final bool enabled;

  const PrinterConfig({
    this.type = PrinterType.simple,
    this.bluetoothMac,
    this.wifiIp,
    this.wifiPort = 9100,
    this.enabled = false,
  });

  Map<String, dynamic> toJson() => {
    'type': type == PrinterType.simple ? 'simple' : 'wifi',
    'bluetoothMac': bluetoothMac,
    'wifiIp': wifiIp,
    'wifiPort': wifiPort,
    'enabled': enabled,
  };

  factory PrinterConfig.fromJson(Map<String, dynamic> json) => PrinterConfig(
    type: json['type'] == 'wifi' ? PrinterType.wifi : PrinterType.simple,
    bluetoothMac: json['bluetoothMac'] as String?,
    wifiIp: json['wifiIp'] as String?,
    wifiPort: json['wifiPort'] as int? ?? 9100,
    enabled: json['enabled'] as bool? ?? false,
  );
}

class PrinterService {
  static Future<Uint8List> generateEscPosReceipt(
    Sale sale, {
    String? shopName,
    String? customerName,
  }) async {
    final bytes = BytesBuilder();
    final List<int> buffer = [];

    void write(String text) {
      buffer.addAll(text.codeUnits);
    }

    void writeLine(String text) {
      write(text);
      buffer.add(0x0A);
    }

    void writeBytes(List<int> data) {
      buffer.addAll(data);
    }

    // Initialize printer
    buffer.addAll([0x1B, 0x40]);

    // Center align
    buffer.addAll([0x1B, 0x61, 0x01]);

    // Bold on
    buffer.addAll([0x1B, 0x45, 0x01]);

    writeLine(shopName ?? 'BluexSofts POS');
    writeLine('');

    // Bold off
    buffer.addAll([0x1B, 0x45, 0x00]);

    writeLine('SALES RECEIPT');
    writeLine('');

    // Left align
    buffer.addAll([0x1B, 0x61, 0x00]);

    writeLine('Receipt #${sale.id.substring(0, 8).toUpperCase()}');
    writeLine(
        'Date: ${sale.createdAt.day}/${sale.createdAt.month}/${sale.createdAt.year}');
    writeLine('Payment: ${sale.paymentMethod}');
    if (customerName != null && customerName != 'Walking Customer') {
      writeLine('Customer: $customerName');
    }
    if (sale.notes.isNotEmpty) {
      writeLine('Notes: ${sale.notes}');
    }
    writeLine('');

    // Separator
    writeLine('${'-' * 32}');
    writeLine('');

    // Header row
    writeLine(
        '${_padRight('Item', 16)} Qty  Price  Total');
    writeLine('${'-' * 32}');

    // Items
    for (final item in sale.saleItems) {
      final name = (item.product?['name'] as String? ?? 'Product');
      final truncated = name.length > 16 ? name.substring(0, 14) : name;
      final qty = '${item.quantity}';
      final price = CurrencyFormatter.formatWithDecimals(item.price);
      final total = CurrencyFormatter.formatWithDecimals(
          item.price * item.quantity);

      writeLine('$truncated');
      writeLine(
          '${' ' * 16} $qty  $price  $total');
    }

    writeLine('');
    writeLine('${'-' * 32}');

    // Totals
    writeLine('${_padRight('Subtotal', 24)}'
        '${CurrencyFormatter.formatWithDecimals(sale.subtotal)}');
    if (sale.tax > 0) {
      writeLine('${_padRight('Tax', 24)}'
          '${CurrencyFormatter.formatWithDecimals(sale.tax)}');
    }
    if (sale.discount > 0) {
      writeLine('${_padRight('Discount', 24)}'
          '-${CurrencyFormatter.formatWithDecimals(sale.discount)}');
    }
    writeLine('${'-' * 32}');

    // Bold on + double height
    buffer.addAll([0x1B, 0x45, 0x01]);
    buffer.addAll([0x1B, 0x21, 0x10]);

    writeLine('${_padRight('TOTAL', 24)}'
        '${CurrencyFormatter.formatWithDecimals(sale.total)}');

    // Reset
    buffer.addAll([0x1B, 0x21, 0x00]);
    buffer.addAll([0x1B, 0x45, 0x00]);

    writeLine('');
    writeLine('');

    // Center
    buffer.addAll([0x1B, 0x61, 0x01]);
    writeLine('Thank you for your business!');
    writeLine('');

    // Cut paper
    buffer.addAll([0x1D, 0x56, 0x00]);

    bytes.add(buffer);
    return bytes.toBytes();
  }

  static String _padRight(String s, int width) {
    if (s.length >= width) return s;
    return s + ' ' * (width - s.length);
  }

  // Placeholder methods for physical printer connection.
  // These require real hardware to test.

  /// Print via TCP/IP to a network thermal printer.
  /// UNTESTED — requires a physical WiFi/Ethernet thermal printer.
  static Future<bool> printViaWifi(String ip, int port, Uint8List data) async {
    try {
      final socket = await Socket.connect(ip, port,
          timeout: const Duration(seconds: 5));
      socket.add(data);
      await socket.flush();
      await socket.close();
      return true;
    } catch (e) {
      debugPrint('[PrinterService] WiFi print failed: $e');
      return false;
    }
  }

  /// Print via Bluetooth to a paired thermal printer.
  /// UNTESTED — requires a physical Bluetooth thermal printer.
  static Future<bool> printViaBluetooth(
      String macAddress, Uint8List data) async {
    // TODO: Implement with esc_pos_bluetooth package.
    // The connection flow is:
    //   1. Discover and pair with the printer by MAC.
    //   2. Create a BluetoothConnection.
    //   3. Write ESC/POS bytes and disconnect.
    //
    // Pseudo-code (requires 'esc_pos_bluetooth' package):
    //   final printer = BluetoothPrinter(macAddress);
    //   await printer.connect();
    //   await printer.writeBytes(data);
    //   await printer.disconnect();
    //
    // This cannot be tested without a physical Bluetooth thermal printer.
    debugPrint('[PrinterService] Bluetooth print not yet implemented for $macAddress');
    return false;
  }

  /// Send a receipt to the configured printer.
  /// Uses the appropriate method based on printer type.
  /// UNTESTED on real hardware.
  static Future<bool> printReceiptEscPos(
    Sale sale, {
    PrinterConfig? config,
    String? shopName,
    String? customerName,
  }) async {
    if (config == null || !config.enabled) return false;

    final data = await generateEscPosReceipt(sale,
        shopName: shopName, customerName: customerName);

    if (config.type == PrinterType.wifi) {
      if (config.wifiIp == null || config.wifiIp!.isEmpty) {
        debugPrint('[PrinterService] WiFi printer IP not configured');
        return false;
      }
      return printViaWifi(config.wifiIp!, config.wifiPort, data);
    } else {
      if (config.bluetoothMac == null || config.bluetoothMac!.isEmpty) {
        debugPrint('[PrinterService] Bluetooth printer MAC not configured');
        return false;
      }
      return printViaBluetooth(config.bluetoothMac!, data);
    }
  }
}
