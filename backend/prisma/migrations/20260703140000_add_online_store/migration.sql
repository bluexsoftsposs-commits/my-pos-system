-- AlterTable: add slug to Shop (nullable initially to populate)
ALTER TABLE "Shop" ADD COLUMN "slug" TEXT;

-- Generate slugs for existing shops
UPDATE "Shop" SET "slug" = LOWER(REGEXP_REPLACE("shopName", '[^a-zA-Z0-9\s-]', '', 'g'));
UPDATE "Shop" SET "slug" = LOWER(REPLACE("slug", ' ', '-'));
UPDATE "Shop" SET "slug" = LOWER(REPLACE("slug", '--', '-'));
UPDATE "Shop" SET "slug" = CONCAT("slug", '-', SUBSTRING(MD5("id"::text)::text, 1, 6)) WHERE "slug" IN (SELECT "slug" FROM "Shop" GROUP BY "slug" HAVING COUNT(*) > 1);

-- Make slug NOT NULL and unique
ALTER TABLE "Shop" ALTER COLUMN "slug" SET NOT NULL;
ALTER TABLE "Shop" ADD CONSTRAINT "Shop_slug_key" UNIQUE ("slug");

-- AlterTable: add isVisibleOnline to Product
ALTER TABLE "Product" ADD COLUMN "isVisibleOnline" BOOLEAN NOT NULL DEFAULT true;

-- CreateTable: OnlineOrder
CREATE TABLE "OnlineOrder" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "customerName" TEXT NOT NULL,
    "customerPhone" TEXT NOT NULL,
    "customerAddress" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "totalAmount" DOUBLE PRECISION NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'online_store',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OnlineOrder_pkey" PRIMARY KEY ("id")
);

-- CreateTable: OnlineOrderItem
CREATE TABLE "OnlineOrderItem" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,
    "subtotal" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "OnlineOrderItem_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "OnlineOrder" ADD CONSTRAINT "OnlineOrder_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OnlineOrderItem" ADD CONSTRAINT "OnlineOrderItem_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "OnlineOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OnlineOrderItem" ADD CONSTRAINT "OnlineOrderItem_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
