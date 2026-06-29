import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  Shop? _shop;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  Shop? get shop => _shop;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isSuperAdmin => _user?.role == 'SUPER_ADMIN';
  bool get hasActiveSubscription => _shop?.hasActiveSubscription ?? false;
  bool get requiresPayment => _shop?.requiresPayment ?? true;

  final _authService = AuthService();

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await _authService.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    final shopData = prefs.getString('shop_data');

    if (userData != null && shopData != null) {
      _user = AppUser.fromJson(jsonDecode(userData));
      _shop = Shop.fromJson(jsonDecode(shopData));
      _status = AuthStatus.authenticated;
      notifyListeners();
    } else {
      try {
        final data = await _authService.getMe();
        if (data != null) {
          _user = AppUser.fromJson(data['user']);
          _shop = Shop.fromJson(data['shop']);
          _status = AuthStatus.authenticated;
          await _persistSession();
        } else {
          await _authService.clearToken();
          _status = AuthStatus.unauthenticated;
        }
      } catch (_) {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    }
  }

  Future<bool> login({
    required String shopName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(shopName: shopName, email: email, password: password);
      if (data != null) {
        await _authService.saveToken(data['token']);
        _user = AppUser.fromJson({
          ...data['user'],
          'shopId': data['shop']['id'],
        });
        _shop = Shop.fromJson(data['shop']);
        _status = AuthStatus.authenticated;
        await _persistSession();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '$e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String shopName,
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.register(shopName: shopName, name: name, email: email, password: password);
      if (data != null) {
        await _authService.saveToken(data['token']);
        _user = AppUser.fromJson({
          ...data['user'],
          'shopId': data['shop']['id'],
        });
        _shop = Shop.fromJson(data['shop']);
        _status = AuthStatus.authenticated;
        await _persistSession();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '$e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.clearToken();
    _user = null;
    _shop = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user != null) await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    if (_shop != null) await prefs.setString('shop_data', jsonEncode(_shop!.toJson()));
  }

  Future<void> refreshSubscription() async {
    try {
      final data = await _authService.getMe();
      if (data != null && data['shop'] != null) {
        final shopData = data['shop'];
        if (_shop != null) {
          _shop = Shop(
            id: _shop!.id,
            shopName: _shop!.shopName,
            subscriptionPlan: shopData['subscriptionPlan'] ?? _shop!.subscriptionPlan,
            subscriptionStatus: shopData['subscriptionStatus'] ?? _shop!.subscriptionStatus,
            subscriptionEndsAt: shopData['subscriptionEndsAt'] != null
                ? DateTime.parse(shopData['subscriptionEndsAt'] as String)
                : _shop!.subscriptionEndsAt,
            isActive: _shop!.isActive,
          );
          await _persistSession();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<String?> forgotPassword({
    required String shopName,
    required String email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final message = await _authService.forgotPassword(shopName: shopName, email: email);
      _isLoading = false;
      notifyListeners();
      return message;
    } catch (e) {
      _error = '$e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> resetPassword({
    required String token,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final message = await _authService.resetPassword(token: token, password: password);
      _isLoading = false;
      notifyListeners();
      return message;
    } catch (e) {
      _error = '$e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> resendVerification() async {
    if (_user == null || _shop == null) return null;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final message = await _authService.resendVerification(
        email: _user!.email,
        shopId: _shop!.id,
      );
      _isLoading = false;
      notifyListeners();
      return message;
    } catch (e) {
      _error = '$e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  bool get isEmailVerified => _user?.emailVerified ?? true;

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
