class ShopCategoryHelper {
  static const _restaurant = 'Restaurant';
  static const _pharmacy = 'Pharmacy';
  static const _clothing = 'Clothing';
  static const _electronics = 'Electronics';
  static const _grocery = 'Grocery';

  // ── Labels ──────────────────────────────────────────────────────

  static String productLabel(String? category) {
    switch (category) {
      case _restaurant: return 'Menu Items';
      case _pharmacy:   return 'Medicines';
      case _clothing:   return 'Apparel';
      case _electronics: return 'Products & Parts';
      default:          return 'Products';
    }
  }

  static String searchHint(String? category) {
    switch (category) {
      case _restaurant: return 'Search menu items...';
      case _pharmacy:   return 'Search medicines...';
      default:          return 'Search products, SKUs, or categories...';
    }
  }

  static String lowStockLabel(String? category) {
    switch (category) {
      case _pharmacy: return 'Expiring Medicines';
      case _restaurant: return 'Low Ingredients';
      default: return 'Low Stock';
    }
  }

  static String salesTitle(String? category) {
    switch (category) {
      case _restaurant: return 'Orders History';
      default: return 'Sales History';
    }
  }

  static String salesSubtitle(String? category) {
    switch (category) {
      case _restaurant: return 'Track your restaurant orders.';
      case _pharmacy: return 'Track medicine sales and prescriptions.';
      default: return 'Track and manage your retail transactions.';
    }
  }

  static String categoryColumnLabel(String? category) {
    switch (category) {
      case _restaurant: return 'Table';
      default: return '';
    }
  }

  // ── Feature flags ───────────────────────────────────────────────

  static bool hasTableService(String? category) => category == _restaurant;
  static bool hasExpiryTracking(String? category) => category == _pharmacy;
  static bool hasVariants(String? category) => category == _clothing || category == _electronics;
  static bool hasPrescriptionTracking(String? category) => category == _pharmacy;
  static bool hasUnitTracking(String? category) => category == _grocery;

  static bool hasWarrantyTracking(String? category) => category == _electronics;
  static bool hasSeasonalTracking(String? category) => category == _clothing;
  static bool hasMenuItems(String? category) => category == _restaurant;

  // ── Settings labels ─────────────────────────────────────────────

  static String categorySettingsSectionTitle(String? category) {
    switch (category) {
      case _pharmacy: return 'Pharmacy Settings';
      case _restaurant: return 'Restaurant Settings';
      case _clothing: return 'Apparel Settings';
      default: return '';
    }
  }

  static List<Map<String, dynamic>> categorySettingsToggles(String? category) {
    switch (category) {
      case _pharmacy:
        return [
          {'key': 'expiryNotifications', 'label': 'Expiry Date Notifications', 'defaultValue': true},
          {'key': 'prescriptionRequired', 'label': 'Require Prescription for Controlled Drugs', 'defaultValue': false},
        ];
      case _restaurant:
        return [
          {'key': 'tableService', 'label': 'Table Service Mode', 'defaultValue': true},
          {'key': 'requireTableNumber', 'label': 'Require Table Number for All Orders', 'defaultValue': false},
        ];
      case _clothing:
        return [
          {'key': 'variantTracking', 'label': 'Size/Color Variant Tracking', 'defaultValue': true},
        ];
      default:
        return [];
    }
  }

  // ── POS helpers ─────────────────────────────────────────────────

  static String? extractTableNumber(String notes) {
    if (notes.startsWith('Table:')) {
      return notes.split('Table:').last.trim().split('\n').first;
    }
    return null;
  }

  static String formatTableNotes(String? tableNumber, String otherNotes) {
    final tablePart = tableNumber != null && tableNumber.isNotEmpty ? 'Table: $tableNumber' : '';
    if (tablePart.isEmpty) return otherNotes;
    if (otherNotes.isEmpty) return tablePart;
    return '$tablePart\n$otherNotes';
  }
}
