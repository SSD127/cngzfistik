class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String customers = 'customers';
  static const String customerPages = 'customer_pages';
  static const String pistachioTypes = 'pistachio_types';
  static const String pistachioAttributes = 'pistachio_attributes';
  static const String warehouses = 'warehouses';
  static const String priceHistory = 'price_history';
  static const String inventoryDeposits = 'inventory_deposits';
  static const String stockMovements = 'stock_movements';
  static const String warehouseSummaries = 'warehouse_summaries';
  static const String sales = 'sales';
  static const String purchases = 'purchases';
  static const String cashMovements = 'cash_movements';
  static const String expenses = 'expenses';
  static const String receipts = 'receipts';
  static const String vaultItems = 'vault_items';
  static const String vaultMovements = 'vault_movements';
  static const String monthlySummaries = 'monthly_summaries';
  static const String auditLogs = 'audit_logs';
  static const String transactionCounters = 'transaction_counters';
  static const String systemSettings = 'system_settings';

  static String userDoc(String uid) => '$users/$uid';
  static String customerDoc(String customerId) => '$customers/$customerId';
  static String customerPageDoc(String token) => '$customerPages/$token';
  static String warehouseSummaryDoc(String warehouseId, String typeId) =>
      '$warehouseSummaries/${warehouseId}__$typeId';
  static String monthlySummaryDoc(int year, int month, String customerId) =>
      '$monthlySummaries/${year}_${month}_$customerId';
}
