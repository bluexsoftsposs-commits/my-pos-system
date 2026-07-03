import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale.dart';
import '../core/currency_formatter.dart';

class ReceiptService {
  static const _defaultCustomer = 'Walking Customer';

  static Future<Uint8List> generateReceipt(Sale sale, {String? shopName, String? customerName}) async {
    final pdf = pw.Document();

    final fontData = await _loadFont();
    final font = pw.Font.ttf(fontData.buffer.asByteData());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  shopName ?? 'BluexSofts POS',
                  style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Sales Receipt',
                  style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt #', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                  pw.Text('#${sale.id.substring(0, 8).toUpperCase()}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                  pw.Text('${sale.createdAt.day}/${sale.createdAt.month}/${sale.createdAt.year} ${sale.createdAt.hour}:${sale.createdAt.minute.toString().padLeft(2, '0')}',
                    style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                  pw.Text(sale.paymentMethod, style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              if (customerName != null && customerName != _defaultCustomer)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Customer', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                    pw.Text(customerName, style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              if (sale.notes.isNotEmpty)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Notes', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                    pw.Text(sale.notes, style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Item', style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Qty', style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Price', style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total', style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              ...sale.saleItems.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        item.product?['name'] as String? ?? 'Product',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text('${item.quantity}', style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.SizedBox(width: 8),
                    pw.Text(CurrencyFormatter.formatWithDecimals(item.price), style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      CurrencyFormatter.formatWithDecimals(item.price * item.quantity),
                      style: pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              )),
              pw.Divider(),
              pw.SizedBox(height: 4),
              _buildTotalRow(font, 'Subtotal', CurrencyFormatter.formatWithDecimals(sale.subtotal)),
              if (sale.tax > 0)
                _buildTotalRow(font, 'Tax', CurrencyFormatter.formatWithDecimals(sale.tax)),
              if (sale.discount > 0)
                _buildTotalRow(font, 'Discount', '-${CurrencyFormatter.formatWithDecimals(sale.discount)}'),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text(CurrencyFormatter.formatWithDecimals(sale.total), style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text('Thank you for your business!', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTotalRow(pw.Font fnt, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: fnt, fontSize: 10, color: PdfColors.grey)),
          pw.Text(value, style: pw.TextStyle(font: fnt, fontSize: 10)),
        ],
      ),
    );
  }

  static Future<Uint8List> _loadFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/Poppins-Regular.ttf'); return data.buffer.asUint8List();
    } catch (_) {
      return Uint8List(0);
    }
  }

  static Future<void> printReceipt(Sale sale, {String? shopName, String? customerName}) async {
    try {
      final pdfData = await generateReceipt(sale, shopName: shopName, customerName: customerName);
      await Printing.layoutPdf(
        onLayout: (_) => pdfData,
        name: 'receipt_${sale.id.substring(0, 8)}',
      );
    } catch (e) {
      debugPrint('Print error: $e');
    }
  }

  static Future<void> shareReceipt(Sale sale, {String? shopName, String? customerName}) async {
    try {
      final pdfData = await generateReceipt(sale, shopName: shopName, customerName: customerName);
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'receipt_${sale.id.substring(0, 8)}.pdf',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }
}
