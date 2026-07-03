import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
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
  String _selectedCategory = 'General';
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _imageUrlCtrl;

  bool _uploading = false;
  String? _previewUrl;

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
    _selectedCategory = p?.category ?? 'General';
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? widget.initialBarcode ?? '');
    _imageUrlCtrl = TextEditingController(text: p?.imageUrl ?? widget.initialImageUrl ?? '');
    _previewUrl = p?.imageUrl ?? widget.initialImageUrl;
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
      setState(() => _selectedCategory = result);
    }
    ctrl.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text.trim()),
      'stock': int.parse(_stockCtrl.text.trim()),
      'sku': _skuCtrl.text.trim(),
      'category': _selectedCategory,
      'imageUrl': _imageUrlCtrl.text.trim(),
      'barcode': _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
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
                              ? '🔒 You\'ve reached your product limit. Upgrade to add more.'
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
                          value: cats.contains(_selectedCategory) ? _selectedCategory : null,
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
                                  Text('Add New…'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == '__new__') {
                              _showNewCategoryDialog();
                            } else if (val != null) {
                              setState(() => _selectedCategory = val);
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
