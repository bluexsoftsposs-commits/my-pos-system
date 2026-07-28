import { Request, Response } from 'express';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

// Super admin creates a category (product category, not shop)
export const createCategory = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, description } = req.body;
    if (!name) {
      res.status(400).json({ error: 'Category name is required' });
      return;
    }

    // Since categories are implicit via Product.category field,
    // we create audit log entry and return success
    await prisma.auditLog.create({
      data: {
        userId: req.user!.userId,
        action: 'CREATE_CATEGORY',
        entityType: 'Category',
        entityId: name,
        changes: { name, description },
      },
    });

    res.status(201).json({ success: true, category: { name, description } });
  } catch (error) {
    console.error('createCategory error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const listCategories = async (_req: Request, res: Response): Promise<void> => {
  try {
    // Get distinct categories from products
    const productCategories = await prisma.product.findMany({
      select: { category: true },
      distinct: ['category'],
      orderBy: { category: 'asc' },
    });

    const categories = productCategories.map((p) => p.category);

    const shopCategoryOptions = [
      { value: 'Grocery', label: 'Grocery' },
      { value: 'Electronics', label: 'Electronics' },
      { value: 'Restaurant', label: 'Restaurant' },
      { value: 'Pharmacy', label: 'Pharmacy' },
      { value: 'Clothing', label: 'Clothing' },
      { value: 'General', label: 'General' },
      { value: 'Other', label: 'Other' },
    ];

    res.json({
      success: true,
      productCategories: categories,
      shopCategories: shopCategoryOptions,
    });
  } catch (error) {
    console.error('listCategories error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getCategoryDefaults = async (req: Request, res: Response): Promise<void> => {
  try {
    const category = toString(req.params.category);

    const defaults: Record<string, any> = {};

    switch (category) {
      case 'Grocery':
        defaults.fields = [
          { name: 'barcode', label: 'Barcode', type: 'text', required: false },
          { name: 'unitType', label: 'Unit Type', type: 'select', options: ['kg', 'gram', 'dozen', 'piece', 'liter', 'ml'], required: true },
          { name: 'unitValue', label: 'Unit Value (e.g. 5 for "5 kg")', type: 'number', required: false },
          { name: 'supplierId', label: 'Supplier', type: 'supplier', required: false },
        ];
        defaults.alerts = ['lowStockAlert'];
        break;

      case 'Electronics':
        defaults.fields = [
          { name: 'barcode', label: 'Barcode', type: 'text', required: false },
          { name: 'imei', label: 'IMEI Number', type: 'text', required: false },
          { name: 'warrantyMonths', label: 'Warranty (months)', type: 'number', required: false },
          { name: 'brand', label: 'Brand', type: 'text', required: false },
          { name: 'model', label: 'Model', type: 'text', required: false },
          { name: 'supplierId', label: 'Supplier', type: 'supplier', required: false },
        ];
        defaults.alerts = ['lowStockAlert'];
        break;

      case 'Restaurant':
        defaults.fields = [
          { name: 'isMenuItem', label: 'Menu Item', type: 'boolean', required: false },
          { name: 'recipe', label: 'Recipe / Ingredients', type: 'textarea', required: false },
        ];
        defaults.alerts = [];
        break;

      case 'Pharmacy':
        defaults.fields = [
          { name: 'batchNumber', label: 'Batch Number', type: 'text', required: true },
          { name: 'expiryDate', label: 'Expiry Date', type: 'date', required: true },
          { name: 'manufacturer', label: 'Manufacturer', type: 'text', required: true },
          { name: 'composition', label: 'Composition', type: 'text', required: false },
          { name: 'dosageForm', label: 'Dosage Form', type: 'select', options: ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Drops', 'Inhaler', 'Other'] },
          { name: 'packing', label: 'Packing', type: 'text', required: false },
          { name: 'isControlled', label: 'Controlled Substance', type: 'boolean', required: false },
          { name: 'isPrescriptionOnly', label: 'Prescription Only', type: 'boolean', required: false },
        ];
        defaults.alerts = ['expiryAlert', 'lowStockAlert'];
        break;

      case 'Clothing':
        defaults.fields = [
          { name: 'barcode', label: 'Barcode', type: 'text', required: false },
          { name: 'size', label: 'Size', type: 'text', required: false },
          { name: 'color', label: 'Color', type: 'text', required: false },
          { name: 'season', label: 'Season', type: 'select', options: ['Summer', 'Winter', 'All-season'], required: false },
          { name: 'supplierId', label: 'Supplier', type: 'supplier', required: false },
        ];
        defaults.alerts = ['lowStockAlert'];
        break;

      case 'General':
      case 'Other':
      default:
        defaults.fields = [
          { name: 'barcode', label: 'Barcode', type: 'text', required: false },
          { name: 'supplierId', label: 'Supplier', type: 'supplier', required: false },
        ];
        defaults.alerts = ['lowStockAlert'];
    }

    res.json({ success: true, defaults });
  } catch (error) {
    console.error('getCategoryDefaults error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
