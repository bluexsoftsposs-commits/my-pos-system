import 'package:flutter/foundation.dart';
import '../services/branch_service.dart';

class BranchInfo {
  final String id;
  final String name;
  final String address;
  final String phone;

  BranchInfo({required this.id, required this.name, this.address = '', this.phone = ''});

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class BranchProvider with ChangeNotifier {
  List<BranchInfo> _branches = [];
  BranchInfo? _selectedBranch;
  Map<String, dynamic>? _report;
  bool _isLoading = false;

  final _branchService = BranchService();

  List<BranchInfo> get branches => _branches;
  BranchInfo? get selectedBranch => _selectedBranch;
  Map<String, dynamic>? get report => _report;
  bool get isLoading => _isLoading;

  void selectBranch(BranchInfo? branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  Future<void> loadBranches() async {
    try {
      final data = await _branchService.getBranches();
      if (data != null) {
        _branches = data.map((e) => BranchInfo.fromJson(e as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> createBranch(String name) async {
    try {
      final data = await _branchService.createBranch({'name': name});
      if (data != null) {
        _branches.add(BranchInfo.fromJson(data));
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> loadBranchReport(String branchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _branchService.getBranchReport(branchId);
      if (data != null) {
        _report = data;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
