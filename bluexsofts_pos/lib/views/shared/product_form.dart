import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/env_config.dart';
import '../../core/api_client.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final String? initialBarcode;
  final String? initialName;
  final String? initialImageUrl;
  final int productsUsed;
  final int productsLimit;
  final String planName;
  const ProductForm({
    super.key,
    this.product,
    this.initialBarcode,
    this.initialName,
    this.initialImageUrl,
    this.productsUsed = 0,
    this.productsLimit = 0,
    this.planName = '',
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  bool get _isAtLimit => !isEditing && widget.productsLimit > 0 && widget.productsUsed >= widget.productsLimit;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _skuCtrl;
  String _selectedProductCategory = 'General';
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _lowStockThresholdCtrl;

  bool _uploading = false;
  String? _previewUrl;

  // Grocery
  String _unitType = 'kg';
  late final TextEditingController _unitValueCtrl;

  // Electronics
  late final TextEditingController _imeiCtrl;
  late final TextEditingController _warrantyCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;

  // Restaurant
  bool _isMenuItem = false;
  late final TextEditingController _recipeCtrl;

  // Pharmacy
  late final TextEditingController _batchCtrl;
  late final TextEditingController _expiryCtrl;
  late final TextEditingController _manufacturerCtrl;
  late final TextEditingController _compositionCtrl;
  String _dosageForm = 'Tablet';
  late final TextEditingController _packingCtrl;
  bool _isControlled = false;
  bool _isPrescriptionOnly = false;

  // Clothing
  late final TextEditingController _sizeCtrl;
  late final TextEditingController _colorCtrl;
  String _season = 'All-season';

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? widget.initialName ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '0');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _selectedProductCategory = p?.category ?? 'General';
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? widget.initialBarcode ?? '');
    _imageUrlCtrl = TextEditingController(text: p?.imageUrl ?? widget.initialImageUrl ?? '');
    _lowStockThresholdCtrl = TextEditingController(text: (p?.lowStockThreshold ?? 5).toString());
    _previewUrl = p?.imageUrl ?? widget.initialImageUrl;

    // Grocery
    _unitType = p?.unitType ?? 'kg';
    _unitValueCtrl = TextEditingController(text: p?.unitValue?.toString() ?? '');

    // Electronics
    _imeiCtrl = TextEditingController(text: p?.imei ?? '');
    _warrantyCtrl = TextEditingController(text: p?.warrantyMonths?.toString() ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _modelCtrl = TextEditingController(text: p?.model ?? '');

    // Restaurant
    _isMenuItem = p?.isMenuItem ?? false;
    _recipeCtrl = TextEditingController(text: p?.recipe ?? '');

    // Pharmacy
    _batchCtrl = TextEditingController(text: p?.batchNumber ?? '');
    _expiryCtrl = TextEditingController(text: p?.expiryDate?.toIso8601String().split('T')[0] ?? '');
    _manufacturerCtrl = TextEditingController(text: p?.manufacturer ?? '');
    _compositionCtrl = TextEditingController(text: p?.composition ?? '');
    _dosageForm = p?.dosageForm ?? 'Tablet';
    _packingCtrl = TextEditingController(text: p?.packing ?? '');
    _isControlled = p?.isControlled ?? false;
    _isPrescriptionOnly = p?.isPrescriptionOnly ?? false;

    // Clothing
    _sizeCtrl = TextEditingController(text: p?.size ?? '');
    _colorCtrl = TextEditingController(text: p?.color ?? '');
    _season = p?.season ?? 'All-season';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _imageUrlCtrl.dispose();
    _lowStockThresholdCtrl.dispose();
    _unitValueCtrl.dispose();
    _imeiCtrl.dispose();
    _warrantyCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _recipeCtrl.dispose();
    _batchCtrl.dispose();
    _expiryCtrl.dispose();
    _manufacturerCtrl.dispose();
    _compositionCtrl.dispose();
    _packingCtrl.dispose();
    _sizeCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploading = true);

    try {
      final token = await _getToken();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      final dio = Dio(BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ));

      final response = await dio.post('/products/upload-image', data: formData);
      final imageUrl = response.data['imageUrl'] as String?;

      if (imageUrl != null && mounted) {
        setState(() {
          _previewUrl = imageUrl;
          _imageUrlCtrl.text = imageUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _getToken() => ApiClient.getToken();

  Future<void> _showNewCategoryDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _selectedProductCategory = result);
    }
    ctrl.dispose();
  }

  Map<String, dynamic> _buildCategoryPayload() {
    final shopCategory = context.read<AuthProvider>().shop?.category ?? 'Other';
    final extras = <String, dynamic>{};
    switch (shopCategory) {
      case 'Grocery':
        extras['unitType'] = _unitType;
        if (_unitValueCtrl.text.trim().isNotEmpty) extras['unitValue'] = double.tryParse(_unitValueCtrl.text.trim());
        break;
      case 'Electronics':
        if (_imeiCtrl.text.trim().isNotEmpty) extras['imei'] = _imeiCtrl.text.trim();
        if (_warrantyCtrl.text.trim().isNotEmpty) extras['warrantyMonths'] = int.tryParse(_warrantyCtrl.text.trim());
        if (_brandCtrl.text.trim().isNotEmpty) extras['brand'] = _brandCtrl.text.trim();
        if (_modelCtrl.text.trim().isNotEmpty) extras['model'] = _modelCtrl.text.trim();
        break;
      case 'Restaurant':
        extras['isMenuItem'] = _isMenuItem;
        if (_recipeCtrl.text.trim().isNotEmpty) extras['recipe'] = _recipeCtrl.text.trim();
        break;
      case 'Pharmacy':
        if (_batchCtrl.text.trim().isNotEmpty) extras['batchNumber'] = _batchCtrl.text.trim();
        if (_expiryCtrl.text.trim().isNotEmpty) extras['expiryDate'] = _expiryCtrl.text.trim();
        if (_manufacturerCtrl.text.trim().isNotEmpty) extras['manufacturer'] = _manufacturerCtrl.text.trim();
        if (_compositionCtrl.text.trim().isNotEmpty) extras['composition'] = _compositionCtrl.text.trim();
        extras['dosageForm'] = _dosageForm;
        if (_packingCtrl.text.trim().isNotEmpty) extras['packing'] = _packingCtrl.text.trim();
        extras['isControlled'] = _isControlled;
        extras['isPrescriptionOnly'] = _isPrescriptionOnly;
        break;
      case 'Clothing':
        if (_sizeCtrl.text.trim().isNotEmpty) extras['size'] = _sizeCtrl.text.trim();
        if (_colorCtrl.text.trim().isNotEmpty) extras['color'] = _colorCtrl.text.trim();
        extras['season'] = _season;
        break;
    }
    return extras;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text.trim()),
      'stock': int.parse(_stockCtrl.text.trim()),
      'sku': _skuCtrl.text.trim(),
      'category': _selectedProductCategory,
      'imageUrl': _imageUrlCtrl.text.trim(),
      'barcode': _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
      'lowStockThreshold': int.tryParse(_lowStockThresholdCtrl.text.trim()) ?? 5,
      ..._buildCategoryPayload(),
    };

    final prov = context.read<ProductProvider>();
    bool success;
    if (isEditing) {
      success = await prov.updateProduct(widget.product!.id, data);
    } else {
      success = await prov.createProduct(data);
    }

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Product updated' : 'Product created'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(isEditing ? 'Edit Product' : 'Add Product', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              if (!isEditing && widget.productsLimit > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isAtLimit
                        ? AppTheme.error.withValues(alpha: 0.1)
                        : AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isAtLimit
                          ? AppTheme.error.withValues(alpha: 0.3)
                          : AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAtLimit ? Icons.lock : Icons.storage,
                        size: 16,
                        color: _isAtLimit ? AppTheme.error : AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isAtLimit
                              ? 'You\'ve reached your product limit. Upgrade to add more.'
                              : 'Products: ${widget.productsUsed} / ${widget.productsLimit}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isAtLimit ? AppTheme.error : Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildImageSection(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: 'Rs ',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid price' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuCtrl,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<ProductProvider>(
                      builder: (context, prov, _) {
                        final cats = prov.categories.where((c) => c != 'All').toList();
                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: cats.contains(_selectedProductCategory) ? _selectedProductCategory : null,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: [
                            ...cats.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                            const DropdownMenuItem(
                              value: '__new__',
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 16),
                                  SizedBox(width: 6),
                                  Text('Add New'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == '__new__') {
                              _showNewCategoryDialog();
                            } else if (val != null) {
                              setState(() => _selectedProductCategory = val);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lowStockThresholdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Threshold',
                  prefixIcon: Icon(Icons.warning_amber),
                  hintText: 'Alert when stock falls below this',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeCtrl,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  hintText: 'Scan or enter barcode number',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final barcode = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => const _SimpleBarcodeInput(),
                        ),
                      );
                      if (barcode != null && mounted) {
                        _barcodeCtrl.text = barcode;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Or paste image URL',
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://...',
                ),
              ),
              _buildCategorySpecificFields(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isAtLimit ? null : _submit,
                child: Text(isEditing ? 'Update Product' : 'Create Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySpecificFields() {
    final shopCategory = context.watch<AuthProvider>().shop?.category ?? 'Other';

    switch (shopCategory) {
      case 'Grocery':
        return _buildGroceryFields();
      case 'Electronics':
        return _buildElectronicsFields();
      case 'Restaurant':
        return _buildRestaurantFields();
      case 'Pharmacy':
        return _buildPharmacyFields();
      case 'Clothing':
        return _buildClothingFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionHeader(IconData icon, String label) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6C5CE7))),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildGroceryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.shopping_basket, 'Grocery Fields'),
        DropdownButtonFormField<String>(
          value: _unitType,
          decoration: const InputDecoration(labelText: 'Unit Type', prefixIcon: Icon(Icons.scale)),
          items: ['kg', 'gram', 'dozen', 'piece', 'liter', 'ml']
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
          onChanged: (v) => setState(() => _unitType = v ?? 'kg'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _unitValueCtrl,
          decoration: const InputDecoration(
            labelText: 'Unit Value (e.g. 5 for "5 kg")',
            prefixIcon: Icon(Icons.tag),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildElectronicsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.electrical_services, 'Electronics Fields'),
        TextFormField(
          controller: _imeiCtrl,
          decoration: const InputDecoration(labelText: 'IMEI Number', prefixIcon: Icon(Icons.qr_code)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _warrantyCtrl,
          decoration: const InputDecoration(labelText: 'Warranty (months)', prefixIcon: Icon(Icons.timer)),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _brandCtrl,
          decoration: const InputDecoration(labelText: 'Brand', prefixIcon: Icon(Icons.business)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _modelCtrl,
          decoration: const InputDecoration(labelText: 'Model', prefixIcon: Icon(Icons.settings)),
        ),
      ],
    );
  }

  Widget _buildRestaurantFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.restaurant, 'Restaurant Fields'),
        CheckboxListTile(
          title: const Text('This is a Menu Item'),
          value: _isMenuItem,
          onChanged: (v) => setState(() => _isMenuItem = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        if (_isMenuItem) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _recipeCtrl,
            decoration: const InputDecoration(
              labelText: 'Recipe / Ingredients',
              prefixIcon: Icon(Icons.menu_book),
            ),
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  Widget _buildPharmacyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.medication, 'Pharmacy Fields'),
        TextFormField(
          controller: _batchCtrl,
          decoration: const InputDecoration(labelText: 'Batch Number', prefixIcon: Icon(Icons.qr_code)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _expiryCtrl,
          decoration: const InputDecoration(
            labelText: 'Expiry Date', prefixIcon: Icon(Icons.calendar_today),
            hintText: 'YYYY-MM-DD',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _manufacturerCtrl,
          decoration: const InputDecoration(labelText: 'Manufacturer', prefixIcon: Icon(Icons.business)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _compositionCtrl,
          decoration: const InputDecoration(labelText: 'Composition', prefixIcon: Icon(Icons.science)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _dosageForm,
          decoration: const InputDecoration(labelText: 'Dosage Form', prefixIcon: Icon(Icons.medication)),
          items: ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Drops', 'Inhaler', 'Other']
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (v) => setState(() => _dosageForm = v ?? 'Tablet'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _packingCtrl,
          decoration: const InputDecoration(labelText: 'Packing (e.g., 10 tablets)', prefixIcon: Icon(Icons.inventory)),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Controlled Substance'),
          value: _isControlled,
          onChanged: (v) => setState(() => _isControlled = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Prescription Only'),
          value: _isPrescriptionOnly,
          onChanged: (v) => setState(() => _isPrescriptionOnly = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildClothingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.checkroom, 'Clothing Fields'),
        TextFormField(
          controller: _sizeCtrl,
          decoration: const InputDecoration(labelText: 'Size', prefixIcon: Icon(Icons.straighten)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _colorCtrl,
          decoration: const InputDecoration(labelText: 'Color', prefixIcon: Icon(Icons.palette)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _season,
          decoration: const InputDecoration(labelText: 'Season', prefixIcon: Icon(Icons.wb_sunny)),
          items: ['Summer', 'Winter', 'All-season']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _season = v ?? 'All-season'),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _previewUrl != null ? Colors.transparent : AppTheme.darkBorder,
              style: _previewUrl != null ? BorderStyle.none : BorderStyle.solid,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _previewUrl != null && _previewUrl!.isNotEmpty
              ? Stack(
                  children: [
                    Image.network(
                      _previewUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    ),
                    if (_uploading)
                      Container(
                        color: Colors.black45,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                )
              : _buildPlaceholder(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: _uploading ? null : _pickAndUploadImage,
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 18),
            label: Text(_uploading ? 'Uploading...' : 'Upload Image'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 36, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            'No image',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarcodeInput extends StatelessWidget {
  const _SimpleBarcodeInput();

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Barcode')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Barcode Number',
                prefixIcon: Icon(Icons.qr_code_scanner),
              ),
              autofocus: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
              child: const Text('Use Barcode'),
            ),
          ],
        ),
      ),
    );
  }
}
