import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _torchOn = false;
  late AnimationController _scanAnimController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
      cameraResolution: const Size(1280, 720),
      formats: [
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
      ],
    );

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanAnimController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _hasScanned = true;

    _showScanSuccessFeedback();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pop(barcode!.rawValue);
      }
    });
  }

  void _showScanSuccessFeedback() {
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _toggleTorch() {
    _controller?.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  void _switchCamera() {
    _controller?.switchCamera();
  }

  void _openManualEntry() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: Colors.white70),
            SizedBox(width: 10),
            Text('Manual Entry', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter barcode number',
            prefixIcon: Icon(Icons.qr_code_scanner),
          ),
          keyboardType: TextInputType.text,
          style: const TextStyle(color: Colors.white),
          onSubmitted: (value) {
            Navigator.of(ctx).pop();
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(val);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Dark vignette overlay
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.7,
                colors: [Colors.transparent, Color(0xD9000000)],
                stops: [0.4, 1.0],
              ),
            ),
          ),
          // Top toolbar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _toolbarButton(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Column(
                    children: [
                      Text('Scanning...',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('Point at product barcode',
                          style: TextStyle(
                              color: Color(0xFFC8C4D7), fontSize: 12)),
                    ],
                  ),
                  _toolbarButton(
                    icon: _torchOn ? Icons.flash_off : Icons.flash_on,
                    onTap: _toggleTorch,
                    active: _torchOn,
                  ),
                ],
              ),
            ),
          ),
          // Scan viewport frame
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75 * 0.75,
              child: Stack(
                children: [
                  // Corner brackets
                  ..._buildCornerBrackets(),
                  // Animated scan line
                  AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (context, child) {
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: _scanLineAnimation.value *
                            (MediaQuery.of(context).size.width * 0.75 * 0.75),
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF6C5CE7),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7)
                                    .withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Success flash overlay
                  if (_hasScanned)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF6C5CE7), width: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Bottom hint
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom +
                kBottomNavigationBarHeight +
                60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Hold steady for focus',
                  style: TextStyle(color: Color(0xFFC8C4D7), fontSize: 13),
                ),
              ),
            ),
          ),
          // Manual entry + footer
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openManualEntry,
                    icon: const Icon(Icons.keyboard, size: 20),
                    label: const Text('MANUAL ENTRY',
                        style: TextStyle(
                            letterSpacing: 1, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 8,
                      shadowColor:
                          const Color(0xFF6C5CE7).withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'BLUEXSOFTS ENCRYPTED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF6C5CE7)
              : Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const cornerSize = 32.0;
    const borderWidth = 4.0;
    const color = Color(0xFF6C5CE7);

    return [
      // Top-left
      Positioned(
        top: -2,
        left: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: borderWidth),
              left: BorderSide(color: color, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: -2,
        left: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: borderWidth),
              left: BorderSide(color: color, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: -2,
        right: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: borderWidth),
              right: BorderSide(color: color, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: -2,
        right: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: borderWidth),
              right: BorderSide(color: color, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(12),
            ),
          ),
        ),
      ),
    ];
  }
}
