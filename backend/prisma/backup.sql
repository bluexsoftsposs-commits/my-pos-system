CREATE TABLE "Payment" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "shopId" TEXT NOT NULL,
    "amount" REAL NOT NULL,
    "plan" TEXT NOT NULL,
    "paymentMethod" TEXT NOT NULL,
    "transactionId" TEXT NOT NULL DEFAULT '',
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Payment_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO "Payment" ("id", "shopId", "amount", "plan", "paymentMethod", "transactionId", "status", "createdAt", "updatedAt") VALUES ('6c22d998-8453-4e74-bfc2-8f566a6a0656', '0799d854-205c-47f3-89da-042c3d57c4c4', 10000, 'PLATINUM', 'JAZZCASH', 'SIM-JC-TXN-0799d854-1782688061600-1782688061643', 'COMPLETED', 1782688061605, 1782688061648);

CREATE TABLE "Product" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "shopId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL DEFAULT '',
    "price" REAL NOT NULL,
    "stock" INTEGER NOT NULL DEFAULT 0,
    "sku" TEXT NOT NULL DEFAULT '',
    "category" TEXT NOT NULL DEFAULT 'General',
    "imageUrl" TEXT NOT NULL DEFAULT '',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Product_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-BEV-001', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Coca Cola 330ml', '', 1.5, 100, 'BEV-001', 'Beverages', '', 1, 1782687864177, 1782687864177);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-BEV-002', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Pepsi 330ml', '', 1.5, 80, 'BEV-002', 'Beverages', '', 1, 1782687864187, 1782687864187);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-BEV-003', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Mineral Water 500ml', '', 0.75, 200, 'BEV-003', 'Beverages', '', 1, 1782687864198, 1782687864198);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-BEV-004', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Energy Drink Red Bull', '', 2.99, 50, 'BEV-004', 'Beverages', '', 1, 1782687864213, 1782687864213);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-SNK-001', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Lays Classic Chips', '', 1.25, 120, 'SNK-001', 'Snacks', '', 1, 1782687864222, 1782687864222);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-SNK-002', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Pringles Original', '', 2.5, 60, 'SNK-002', 'Snacks', '', 1, 1782687864229, 1782687864229);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-SNK-003', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Oreo Cookies', '', 1.75, 90, 'SNK-003', 'Snacks', '', 1, 1782687864238, 1782687864238);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-SNK-004', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Kit Kat Chocolate', '', 1, 150, 'SNK-004', 'Snacks', '', 1, 1782687864255, 1782687864255);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-BAK-001', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'White Bread Loaf', '', 2.25, 40, 'BAK-001', 'Bakery', '', 1, 1782687864263, 1782687864263);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-BAK-002', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Brown Bread Loaf', '', 2.5, 35, 'BAK-002', 'Bakery', '', 1, 1782687864273, 1782687864273);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-BAK-003', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Croissant', '', 1.5, 25, 'BAK-003', 'Bakery', '', 1, 1782687864281, 1782687864281);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-DAI-001', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Milk 1L', '', 1.2, 75, 'DAI-001', 'Dairy', '', 1, 1782687864291, 1782687864291);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-DAI-002', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Yogurt 500g', '', 1.8, 50, 'DAI-002', 'Dairy', '', 1, 1782687864296, 1782687864296);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-DAI-003', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Cheddar Cheese 200g', '', 3.5, 30, 'DAI-003', 'Dairy', '', 1, 1782687864302, 1782687864302);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-PHA-001', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Paracetamol 500mg', '', 3.99, 60, 'PHA-001', 'Pharmacy', '', 1, 1782687864307, 1782687864307);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-PHA-002', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Ibuprofen 400mg', '', 4.5, 45, 'PHA-002', 'Pharmacy', '', 1, 1782687864315, 1782687864315);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-HYG-001', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Hand Sanitizer 250ml', '', 2.75, 80, 'HYG-001', 'Hygiene', '', 1, 1782687864323, 1782687864323);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-HYG-002', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Face Mask (10 pack)', '', 3, 100, 'HYG-002', 'Hygiene', '', 1, 1782687864329, 1782687864329);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-TOB-001', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Cigarettes Marlboro', '', 5.5, 200, 'TOB-001', 'Tobacco', '', 1, 1782687864335, 1782687864335);
INSERT INTO "Product" ("id", "shopId", "name", "description", "price", "stock", "sku", "category", "imageUrl", "isActive", "createdAt", "updatedAt") VALUES ('seed-ACC-001', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'Lighter', '', 0.99, 150, 'ACC-001', 'Accessories', '', 1, 1782687864340, 1782687864340);

CREATE TABLE "Sale" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "shopId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "total" REAL NOT NULL,
    "subtotal" REAL NOT NULL,
    "tax" REAL NOT NULL DEFAULT 0,
    "discount" REAL NOT NULL DEFAULT 0,
    "paymentMethod" TEXT NOT NULL DEFAULT 'CASH',
    "status" TEXT NOT NULL DEFAULT 'COMPLETED',
    "notes" TEXT NOT NULL DEFAULT '',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Sale_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Sale_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE TABLE "SaleItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "shopId" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "price" REAL NOT NULL,
    "subtotal" REAL NOT NULL,
    CONSTRAINT "SaleItem_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "SaleItem_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "SaleItem_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE TABLE "Shop" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "shopName" TEXT NOT NULL,
    "subscriptionPlan" TEXT NOT NULL DEFAULT 'NONE',
    "subscriptionStatus" TEXT NOT NULL DEFAULT 'PENDING',
    "subscriptionEndsAt" DATETIME,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

INSERT INTO "Shop" ("id", "shopName", "subscriptionPlan", "subscriptionStatus", "subscriptionEndsAt", "isActive", "createdAt", "updatedAt") VALUES ('04c8ef4e-a027-4e73-b43d-fccf139c911f', 'BluexSofts Demo Shop', 'NONE', 'NONE', NULL, 1, 1782687862986, 1782687862986);
INSERT INTO "Shop" ("id", "shopName", "subscriptionPlan", "subscriptionStatus", "subscriptionEndsAt", "isActive", "createdAt", "updatedAt") VALUES ('1ddf153f-fc52-44bc-9ffb-a069b76d3cfb', '__super_admin__', 'PREMIUM', 'ACTIVE', NULL, 1, 1782687863793, 1782687863793);
INSERT INTO "Shop" ("id", "shopName", "subscriptionPlan", "subscriptionStatus", "subscriptionEndsAt", "isActive", "createdAt", "updatedAt") VALUES ('0799d854-205c-47f3-89da-042c3d57c4c4', 'BluexSofts De', 'PLATINUM', 'ACTIVE', 1785280061652, 1, 1782688050761, 1782688061658);

CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "shopId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'CASHIER',
    "name" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "User_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO "User" ("id", "shopId", "email", "passwordHash", "role", "name", "isActive", "createdAt", "updatedAt") VALUES ('8db6ab19-8958-4a06-91be-1e8cce496fad', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'admin@demo.com', '$2a$12$jzB7FkAfjYVv0x9V2ThwGOKlzHVDQFO4fEf33iSp64SPq.Qu8KO4u', 'ADMIN', 'Admin User', 1, 1782687863410, 1782687863410);
INSERT INTO "User" ("id", "shopId", "email", "passwordHash", "role", "name", "isActive", "createdAt", "updatedAt") VALUES ('6983f829-48f3-4eec-ad60-22dd06a95c9c', '04c8ef4e-a027-4e73-b43d-fccf139c911f', 'cashier@demo.com', '$2a$12$AxQ2coiZZ0ef9b44JJu/buzDfKXvtlLlNGjj3Y1vgsziUKKJlFx9i', 'CASHIER', 'John Cashier', 1, 1782687863787, 1782687863787);
INSERT INTO "User" ("id", "shopId", "email", "passwordHash", "role", "name", "isActive", "createdAt", "updatedAt") VALUES ('88bc6d1f-d7ae-47ce-b130-2f90593893a2', '1ddf153f-fc52-44bc-9ffb-a069b76d3cfb', 'super@admin.com', '$2a$12$FxN6kYlw2eL5Po44TjpjD.E8UoLn/BtO06iDsR0LFR9xrPbtKRE06', 'SUPER_ADMIN', 'Super Admin', 1, 1782687864170, 1782687864170);
INSERT INTO "User" ("id", "shopId", "email", "passwordHash", "role", "name", "isActive", "createdAt", "updatedAt") VALUES ('f859b776-8356-4c20-96b4-c3fb44d38762', '0799d854-205c-47f3-89da-042c3d57c4c4', 'ayyanlingop56@gmail.com', '$2a$12$V4MJQmweRMswMiwPWeglPuhkZ4cKcW.O4sWAilqPdwfgwsq5pZEyG', 'ADMIN', 'aslam', 1, 1782688050778, 1782688050778);

CREATE TABLE "_prisma_migrations" (
    "id"                    TEXT PRIMARY KEY NOT NULL,
    "checksum"              TEXT NOT NULL,
    "finished_at"           DATETIME,
    "migration_name"        TEXT NOT NULL,
    "logs"                  TEXT,
    "rolled_back_at"        DATETIME,
    "started_at"            DATETIME NOT NULL DEFAULT current_timestamp,
    "applied_steps_count"   INTEGER UNSIGNED NOT NULL DEFAULT 0
);

INSERT INTO "_prisma_migrations" ("id", "checksum", "finished_at", "migration_name", "logs", "rolled_back_at", "started_at", "applied_steps_count") VALUES ('1e474f45-66b0-46e1-ac0c-c5ceb55e4ba3', '45c32076eedb11b7146673bde630350f5741616e07fdcd3d301235f0eca9465d', 1782687850836, '20260628130058_init', NULL, NULL, 1782687850805, 1);
INSERT INTO "_prisma_migrations" ("id", "checksum", "finished_at", "migration_name", "logs", "rolled_back_at", "started_at", "applied_steps_count") VALUES ('b1d26765-da4e-4c16-a2d6-382f9cd8517f', '01c4ef3390b4f869a3a566ea1a19e7b94a1d8aa8a4b13e9591ba163e7807d07f', 1782687850873, '20260628222057_add_subscription_payments', NULL, NULL, 1782687850841, 1);

