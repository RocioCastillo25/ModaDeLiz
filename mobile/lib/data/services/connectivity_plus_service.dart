import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_service.dart';

/// Implementación de [ConnectivityService] sobre `connectivity_plus`.
class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
