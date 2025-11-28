import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final Logger _logger = Logger();

  // Helper function to safely extract the primary result
  ConnectivityResult _getPrimaryConnection(List<ConnectivityResult> results) {
    // FIX: Using the index operator [0] instead of .first to resolve
    // potential strict linter/compiler issues while still checking isNotEmpty.
    if (results.isNotEmpty) {
      return results[0];
    }
    return ConnectivityResult.none;
  }

  Stream<ConnectivityResult> get connectivityStream =>
      // FIX: Safely map the stream result by extracting the first non-none result
  _connectivity.onConnectivityChanged.map(_getPrimaryConnection as ConnectivityResult Function(ConnectivityResult event));

  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      // FIX: Safely access the first element and compare
      return _getPrimaryConnection(results as List<ConnectivityResult>) != ConnectivityResult.none;
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      return false;
    }
  }

  Future<ConnectivityResult> get connectivityResult async {
    try {
      final results = await _connectivity.checkConnectivity();
      // FIX: Safely access the first element
      return _getPrimaryConnection(results as List<ConnectivityResult>);
    } catch (e) {
      _logger.e('Error getting connectivity result: $e');
      return ConnectivityResult.none;
    }
  }

  Future<bool> get isMobile async {
    final result = await connectivityResult;
    return result == ConnectivityResult.mobile;
  }

  Future<bool> get isWifi async {
    final result = await connectivityResult;
    return result == ConnectivityResult.wifi;
  }

  Future<bool> get isEthernet async {
    final result = await connectivityResult;
    return result == ConnectivityResult.ethernet;
  }

  String getConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
      }
  }

  Future<void> checkAndNotify(Function(bool) callback) async {
    final isOnline = await isConnected;
    callback(isOnline);
  }

  void listenToConnectivityChanges(Function(bool) callback) {
    connectivityStream.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      callback(isOnline);
    });
  }
}