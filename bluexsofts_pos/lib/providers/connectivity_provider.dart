import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service;
  final VoidCallback? _onOnline;
  bool _isOnline = true;
  bool _wasOffline = false;

  bool get isOnline => _isOnline;

  ConnectivityProvider(this._service, {VoidCallback? onOnline})
      : _onOnline = onOnline {
    _init();
  }

  Future<void> _init() async {
    _isOnline = await _service.checkNow();
    _wasOffline = !_isOnline;
    notifyListeners();
    _service.onStatusChanged.listen((online) {
      debugPrint('[ConnectivityProvider] onStatusChanged listened: online=$online _wasOffline=$_wasOffline _isOnline=$_isOnline');
      final transitionedToOnline = online && _wasOffline;
      debugPrint('[ConnectivityProvider]   transitionedToOnline=$transitionedToOnline');
      _wasOffline = !online;
      _isOnline = online;
      notifyListeners();
      if (transitionedToOnline) {
        debugPrint('[ConnectivityProvider]   transitionedToOnline is TRUE -> calling _onOnline?.call()');
        _onOnline?.call();
      } else {
        debugPrint('[ConnectivityProvider]   NOT calling _onOnline');
      }
    });
  }
}