import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/printer_service.dart';
import '../../services/printer_settings_service.dart';

class PrinterSettingsSheet extends StatefulWidget {
  final PrinterConfig initialConfig;

  const PrinterSettingsSheet({super.key, required this.initialConfig});

  @override
  State<PrinterSettingsSheet> createState() => _PrinterSettingsSheetState();
}

class _PrinterSettingsSheetState extends State<PrinterSettingsSheet> {
  late PrinterType _type;
  late TextEditingController _ipCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _macCtrl;
  bool _enabled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initialConfig;
    _type = c.type;
    _enabled = c.enabled;
    _ipCtrl = TextEditingController(text: c.wifiIp ?? '');
    _portCtrl = TextEditingController(text: c.wifiPort.toString());
    _macCtrl = TextEditingController(text: c.bluetoothMac ?? '');
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _macCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final config = PrinterConfig(
      type: _type,
      enabled: _enabled,
      wifiIp: _type == PrinterType.wifi ? _ipCtrl.text.trim() : null,
      wifiPort: _type == PrinterType.wifi
          ? int.tryParse(_portCtrl.text) ?? 9100
          : 9100,
      bluetoothMac:
          _type == PrinterType.simple ? _macCtrl.text.trim() : null,
    );
    await PrinterSettingsService.saveConfig(config);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Printer Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your receipt printer',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Enable Receipt Printer',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                _type == PrinterType.simple
                    ? 'USB / Bluetooth Thermal'
                    : 'WiFi / Ethernet Thermal',
                style: TextStyle(color: Colors.grey[500]),
              ),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
              activeColor: AppTheme.accent,
            ),
            const SizedBox(height: 12),
            Text(
              'Printer Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _typeChip(
                    label: 'Simple Printer',
                    subtitle: 'USB / Bluetooth',
                    icon: Icons.bluetooth,
                    selected: _type == PrinterType.simple,
                    onTap: () => setState(() => _type = PrinterType.simple),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _typeChip(
                    label: 'WiFi Printer',
                    subtitle: 'TCP/IP Network',
                    icon: Icons.wifi,
                    selected: _type == PrinterType.wifi,
                    onTap: () => setState(() => _type = PrinterType.wifi),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_type == PrinterType.wifi) ...[
              TextField(
                controller: _ipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Printer IP Address',
                  prefixIcon: Icon(Icons.wifi),
                  hintText: '192.168.1.100',
                ),
                keyboardType: TextInputType.url,
                enabled: _enabled,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portCtrl,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  prefixIcon: Icon(Icons.settings_ethernet),
                  hintText: '9100',
                ),
                keyboardType: TextInputType.number,
                enabled: _enabled,
              ),
            ] else ...[
              TextField(
                controller: _macCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bluetooth MAC Address',
                  prefixIcon: Icon(Icons.bluetooth),
                  hintText: '00:11:22:AA:BB:CC',
                ),
                enabled: _enabled,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _enabled ? _discoverBluetooth : null,
                  icon: const Icon(Icons.search),
                  label: const Text('Discover Bluetooth Printers'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withOpacity(0.2)
              : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.darkBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppTheme.accent : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey,
                )),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  void _discoverBluetooth() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bluetooth discovery requires a real device'),
        backgroundColor: AppTheme.warning,
      ),
    );
  }
}
