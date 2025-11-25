import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final Logger _logger = Logger();

  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged.map((result) => result.first);

  Future<bool> get isConnected async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.first != ConnectivityResult.none;
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      return false;
    }
  }

  Future<ConnectivityResult> get connectivityResult async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.first;
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
      default:
        return 'Unknown';
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