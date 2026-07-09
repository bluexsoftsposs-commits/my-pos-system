import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();

  Stream<bool> get onStatusChanged => _statusController.stream;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
    return _isOnline;
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    debugPrint('[ConnectivityService] _onConnectivityChanged fired');
    debugPrint('[ConnectivityService]   results raw: $results');
    debugPrint('[ConnectivityService]   results length: ${results.length}');
    for (int i = 0; i < results.length; i++) {
      debugPrint('[ConnectivityService]   results[$i] = ${results[i]} .name=${results[i].name} .index=${results[i].index}');
    }
    debugPrint('[ConnectivityService]   contains none? ${results.contains(ConnectivityResult.none)}');
    final online = !results.contains(ConnectivityResult.none);
    debugPrint('[ConnectivityService]   computed online=$online');
    debugPrint('[ConnectivityService]   _isOnline was=${_isOnline}');
    if (online != _isOnline) {
      _isOnline = online;
      debugPrint('[ConnectivityService]   state CHANGED -> adding to stream: online=$online');
      _statusController.add(online);
    } else {
      debugPrint('[ConnectivityService]   no change, NOT adding to stream');
    }
  }

  void dispose() {
    _statusController.close();
  }
}