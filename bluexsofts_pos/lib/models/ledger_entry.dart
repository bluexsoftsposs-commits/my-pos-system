class LedgerEntry {
  final String id;
  final String shopId;
  final String customerId;
  final String type; // "DEBIT" or "CREDIT"
  final double amount;
  final String? saleId;
  final String note;
  final DateTime createdAt;

  LedgerEntry({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.type,
    required this.amount,
    this.saleId,
    this.note = '',
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      customerId: json['customerId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      saleId: json['saleId'] as String?,
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isDebit => type == 'DEBIT';
  bool get isCredit => type == 'CREDIT';
}
