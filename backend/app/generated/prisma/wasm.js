
Object.defineProperty(exports, "__esModule", { value: true });

const {
  Decimal,
  objectEnumValues,
  makeStrictEnum,
  Public,
  getRuntime,
  skip
} = require('./runtime/index-browser.js')


const Prisma = {}

exports.Prisma = Prisma
exports.$Enums = {}

/**
 * Prisma Client JS version: 5.22.0
 * Query Engine version: 605197351a3c8bdd595af2d2a9bc3025bca48ea2
 */
Prisma.prismaVersion = {
  client: "5.22.0",
  engine: "605197351a3c8bdd595af2d2a9bc3025bca48ea2"
}

Prisma.PrismaClientKnownRequestError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientKnownRequestError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)};
Prisma.PrismaClientUnknownRequestError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientUnknownRequestError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.PrismaClientRustPanicError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientRustPanicError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.PrismaClientInitializationError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientInitializationError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.PrismaClientValidationError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientValidationError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.NotFoundError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`NotFoundError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.Decimal = Decimal

/**
 * Re-export of sql-template-tag
 */
Prisma.sql = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`sqltag is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.empty = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`empty is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.join = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`join is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.raw = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`raw is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.validator = Public.validator

/**
* Extensions
*/
Prisma.getExtensionContext = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`Extensions.getExtensionContext is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.defineExtension = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`Extensions.defineExtension is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}

/**
 * Shorthand utilities for JSON filtering
 */
Prisma.DbNull = objectEnumValues.instances.DbNull
Prisma.JsonNull = objectEnumValues.instances.JsonNull
Prisma.AnyNull = objectEnumValues.instances.AnyNull

Prisma.NullTypes = {
  DbNull: objectEnumValues.classes.DbNull,
  JsonNull: objectEnumValues.classes.JsonNull,
  AnyNull: objectEnumValues.classes.AnyNull
}



/**
 * Enums
 */

exports.Prisma.TransactionIsolationLevel = makeStrictEnum({
  ReadUncommitted: 'ReadUncommitted',
  ReadCommitted: 'ReadCommitted',
  RepeatableRead: 'RepeatableRead',
  Serializable: 'Serializable'
});

exports.Prisma.PlanScalarFieldEnum = {
  id: 'id',
  name: 'name',
  billingCycle: 'billingCycle',
  price: 'price',
  setupFee: 'setupFee',
  originalSetupFee: 'originalSetupFee',
  salesPointsLimit: 'salesPointsLimit',
  productsLimit: 'productsLimit',
  fbrConnect: 'fbrConnect',
  techSupport: 'techSupport',
  onlineStore: 'onlineStore',
  updates: 'updates',
  isActive: 'isActive',
  createdAt: 'createdAt'
};

exports.Prisma.ShopSubscriptionScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  planId: 'planId',
  startDate: 'startDate',
  endDate: 'endDate',
  status: 'status',
  createdAt: 'createdAt'
};

exports.Prisma.ShopScalarFieldEnum = {
  id: 'id',
  shopName: 'shopName',
  subscriptionPlan: 'subscriptionPlan',
  subscriptionStatus: 'subscriptionStatus',
  subscriptionEndsAt: 'subscriptionEndsAt',
  isActive: 'isActive',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  category: 'category',
  slug: 'slug',
  subCategoryId: 'subCategoryId',
  supplierId: 'supplierId',
  managedBySubAdminId: 'managedBySubAdminId'
};

exports.Prisma.BranchScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  name: 'name',
  address: 'address',
  phone: 'phone',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.PaymentScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  amount: 'amount',
  plan: 'plan',
  paymentMethod: 'paymentMethod',
  transactionId: 'transactionId',
  status: 'status',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.UserScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  email: 'email',
  passwordHash: 'passwordHash',
  role: 'role',
  name: 'name',
  isActive: 'isActive',
  emailVerified: 'emailVerified',
  canAccessSuppliers: 'canAccessSuppliers',
  verificationToken: 'verificationToken',
  currentSessionToken: 'currentSessionToken',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.PasswordResetTokenScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  token: 'token',
  expiresAt: 'expiresAt',
  usedAt: 'usedAt',
  createdAt: 'createdAt'
};

exports.Prisma.ProductScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  name: 'name',
  description: 'description',
  price: 'price',
  stock: 'stock',
  sku: 'sku',
  category: 'category',
  imageUrl: 'imageUrl',
  isActive: 'isActive',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  barcode: 'barcode',
  isVisibleOnline: 'isVisibleOnline',
  lowStockThreshold: 'lowStockThreshold',
  unitType: 'unitType',
  unitValue: 'unitValue',
  imei: 'imei',
  warrantyMonths: 'warrantyMonths',
  brand: 'brand',
  model: 'model',
  isMenuItem: 'isMenuItem',
  recipe: 'recipe',
  batchNumber: 'batchNumber',
  expiryDate: 'expiryDate',
  manufacturer: 'manufacturer',
  composition: 'composition',
  dosageForm: 'dosageForm',
  packing: 'packing',
  isControlled: 'isControlled',
  isPrescriptionOnly: 'isPrescriptionOnly',
  size: 'size',
  color: 'color',
  season: 'season',
  supplierId: 'supplierId'
};

exports.Prisma.SaleScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  userId: 'userId',
  total: 'total',
  subtotal: 'subtotal',
  tax: 'tax',
  discount: 'discount',
  paymentMethod: 'paymentMethod',
  status: 'status',
  notes: 'notes',
  createdAt: 'createdAt',
  customerId: 'customerId',
  branchId: 'branchId'
};

exports.Prisma.InvoiceScalarFieldEnum = {
  id: 'id',
  invoiceNumber: 'invoiceNumber',
  saleId: 'saleId',
  shopId: 'shopId',
  userId: 'userId',
  total: 'total',
  subtotal: 'subtotal',
  tax: 'tax',
  discount: 'discount',
  paymentMethod: 'paymentMethod',
  createdAt: 'createdAt'
};

exports.Prisma.SaleItemScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  saleId: 'saleId',
  productId: 'productId',
  quantity: 'quantity',
  price: 'price',
  subtotal: 'subtotal'
};

exports.Prisma.OnlineOrderScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  customerName: 'customerName',
  customerPhone: 'customerPhone',
  customerAddress: 'customerAddress',
  status: 'status',
  totalAmount: 'totalAmount',
  source: 'source',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.OnlineOrderItemScalarFieldEnum = {
  id: 'id',
  orderId: 'orderId',
  productId: 'productId',
  quantity: 'quantity',
  price: 'price',
  subtotal: 'subtotal'
};

exports.Prisma.CustomerScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  name: 'name',
  phone: 'phone',
  totalOwed: 'totalOwed',
  totalPaid: 'totalPaid',
  lastPaymentAt: 'lastPaymentAt',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.LedgerEntryScalarFieldEnum = {
  id: 'id',
  shopId: 'shopId',
  customerId: 'customerId',
  type: 'type',
  amount: 'amount',
  saleId: 'saleId',
  note: 'note',
  createdAt: 'createdAt'
};

exports.Prisma.SupplierScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  supplierName: 'supplierName',
  businessName: 'businessName',
  gstNumber: 'gstNumber',
  panNumber: 'panNumber',
  bankAccountNo: 'bankAccountNo',
  bankName: 'bankName',
  ifscCode: 'ifscCode',
  phone: 'phone',
  email: 'email',
  address: 'address',
  city: 'city',
  state: 'state',
  pincode: 'pincode',
  totalSalesValue: 'totalSalesValue',
  totalPayments: 'totalPayments',
  pendingBalance: 'pendingBalance',
  isVerified: 'isVerified',
  isActive: 'isActive',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.SupplierTransactionScalarFieldEnum = {
  id: 'id',
  supplierId: 'supplierId',
  type: 'type',
  amount: 'amount',
  description: 'description',
  referenceNo: 'referenceNo',
  createdAt: 'createdAt',
  createdBy: 'createdBy'
};

exports.Prisma.SubAdminScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  title: 'title',
  region: 'region',
  permissions: 'permissions',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.AuditLogScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  action: 'action',
  entityType: 'entityType',
  entityId: 'entityId',
  changes: 'changes',
  ipAddress: 'ipAddress',
  createdAt: 'createdAt'
};

exports.Prisma.SystemStateScalarFieldEnum = {
  key: 'key',
  value: 'value'
};

exports.Prisma.PendingApprovalScalarFieldEnum = {
  id: 'id',
  subAdminId: 'subAdminId',
  action: 'action',
  entityType: 'entityType',
  entityId: 'entityId',
  payload: 'payload',
  status: 'status',
  reviewedBy: 'reviewedBy',
  reviewNote: 'reviewNote',
  createdAt: 'createdAt',
  reviewedAt: 'reviewedAt'
};

exports.Prisma.SortOrder = {
  asc: 'asc',
  desc: 'desc'
};

exports.Prisma.JsonNullValueInput = {
  JsonNull: Prisma.JsonNull
};

exports.Prisma.NullableJsonNullValueInput = {
  DbNull: Prisma.DbNull,
  JsonNull: Prisma.JsonNull
};

exports.Prisma.QueryMode = {
  default: 'default',
  insensitive: 'insensitive'
};

exports.Prisma.NullsOrder = {
  first: 'first',
  last: 'last'
};

exports.Prisma.JsonNullValueFilter = {
  DbNull: Prisma.DbNull,
  JsonNull: Prisma.JsonNull,
  AnyNull: Prisma.AnyNull
};
exports.ShopCategory = exports.$Enums.ShopCategory = {
  Grocery: 'Grocery',
  Electronics: 'Electronics',
  Restaurant: 'Restaurant',
  Pharmacy: 'Pharmacy',
  Clothing: 'Clothing',
  General: 'General',
  Other: 'Other'
};

exports.Prisma.ModelName = {
  Plan: 'Plan',
  ShopSubscription: 'ShopSubscription',
  Shop: 'Shop',
  Branch: 'Branch',
  Payment: 'Payment',
  User: 'User',
  PasswordResetToken: 'PasswordResetToken',
  Product: 'Product',
  Sale: 'Sale',
  Invoice: 'Invoice',
  SaleItem: 'SaleItem',
  OnlineOrder: 'OnlineOrder',
  OnlineOrderItem: 'OnlineOrderItem',
  Customer: 'Customer',
  LedgerEntry: 'LedgerEntry',
  Supplier: 'Supplier',
  SupplierTransaction: 'SupplierTransaction',
  SubAdmin: 'SubAdmin',
  AuditLog: 'AuditLog',
  SystemState: 'SystemState',
  PendingApproval: 'PendingApproval'
};

/**
 * This is a stub Prisma Client that will error at runtime if called.
 */
class PrismaClient {
  constructor() {
    return new Proxy(this, {
      get(target, prop) {
        let message
        const runtime = getRuntime()
        if (runtime.isEdge) {
          message = `PrismaClient is not configured to run in ${runtime.prettyName}. In order to run Prisma Client on edge runtime, either:
- Use Prisma Accelerate: https://pris.ly/d/accelerate
- Use Driver Adapters: https://pris.ly/d/driver-adapters
`;
        } else {
          message = 'PrismaClient is unable to run in this browser environment, or has been bundled for the browser (running in `' + runtime.prettyName + '`).'
        }
        
        message += `
If this is unexpected, please open an issue: https://pris.ly/prisma-prisma-bug-report`

        throw new Error(message)
      }
    })
  }
}

exports.PrismaClient = PrismaClient

Object.assign(exports, Prisma)
