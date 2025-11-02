import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';

/// Service to monitor connectivity and trigger sync when online
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final SyncService _syncService;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  String? _currentUserId;

  ConnectivityService(this._syncService);

  /// Start monitoring connectivity
  void startMonitoring(String userId) {
    _currentUserId = userId;
    
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((result) => 
        result != ConnectivityResult.none
      );
      
      if (isOnline && _currentUserId != null) {
        _onConnectivityRestored();
      }
    });

    // Trigger initial sync if online
    _checkAndSync();
  }

  Future<void> _onConnectivityRestored() async {
    print('Connectivity restored, syncing pending actions...');
    if (_currentUserId != null) {
      try {
        await _syncService.syncPendingActions(_currentUserId!);
      } catch (e) {
        print('Auto-sync failed: $e');
      }
    }
  }

  Future<void> _checkAndSync() async {
    final result = await _connectivity.checkConnectivity();
    final isOnline = result.any((r) => r != ConnectivityResult.none);
    
    if (isOnline && _currentUserId != null) {
      await _syncService.syncPendingActions(_currentUserId!);
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
  }

  /// Check if currently online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }
}
